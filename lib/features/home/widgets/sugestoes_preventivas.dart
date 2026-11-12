import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SugestaoPreventiva {
  final String titulo;
  final String explicacao;

  const SugestaoPreventiva({required this.titulo, required this.explicacao});
}

class SugestoesPreventivas extends StatefulWidget {
  final int? idPet;

  const SugestoesPreventivas({super.key, required this.idPet});

  @override
  State<SugestoesPreventivas> createState() => _SugestoesPreventivasState();
}

class _SugestoesPreventivasState extends State<SugestoesPreventivas> {
  final _supabase = Supabase.instance.client;

  late Future<List<SugestaoPreventiva>> _sugestoes;

  @override
  void initState() {
    super.initState();
    _sugestoes = _buscarSugestoes();
  }

  @override
  void didUpdateWidget(covariant SugestoesPreventivas oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.idPet != widget.idPet) {
      _sugestoes = _buscarSugestoes();
    }
  }

  void _atualizar() {
    setState(() {
      _sugestoes = _buscarSugestoes();
    });
  }

  String _dataIso(DateTime data) {
    final ano = data.year.toString().padLeft(4, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');

    return '$ano-$mes-$dia';
  }

  String _dataBrasileira(String dataIso) {
    final partes = dataIso.split('-');
    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  Future<List<SugestaoPreventiva>> _buscarSugestoes() async {
    final idPet = widget.idPet;
    if (idPet == null) return [];

    final pet = await _supabase
        .from('pet')
        .select('nome, especie, data_nascimento')
        .eq('id_pet', idPet)
        .maybeSingle();

    if (pet == null) return [];

    final registros = await _supabase
        .from('registro_saude')
        .select('tipo, data_proxima_dose, proxima_dose_concluida')
        .eq('id_pet', idPet);

    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final inicioAnterior = DateTime(hoje.year, hoje.month, hoje.day - 14);
    final inicioAtual = DateTime(hoje.year, hoje.month, hoje.day - 7);

    final passeios = await _supabase
        .from('atividade_pet')
        .select('ocorrido_em')
        .eq('id_pet', idPet)
        .eq('tipo', 'passeio')
        .gte('ocorrido_em', inicioAnterior.toUtc().toIso8601String())
        .lt('ocorrido_em', hoje.toUtc().toIso8601String());

    final nomePet = pet['nome'] as String;
    final especie = (pet['especie'] as String?)?.toLowerCase() ?? '';
    final sugestoes = <SugestaoPreventiva>[];

    // Regra 1: próxima dose informada e ainda não concluída.
    final dosesPendentes = <String>[];

    for (final registro in registros) {
      if (registro['tipo'] != 'vacina') continue;
      if (registro['proxima_dose_concluida'] == true) continue;

      final data = registro['data_proxima_dose'] as String?;
      if (data != null) dosesPendentes.add(data);
    }

    dosesPendentes.sort();

    if (dosesPendentes.isNotEmpty) {
      final proximaData = dosesPendentes.first;
      final hojeIso = _dataIso(hoje);
      final limiteIso = _dataIso(DateTime(hoje.year, hoje.month, hoje.day + 7));

      if (proximaData.compareTo(hojeIso) < 0) {
        sugestoes.add(
          SugestaoPreventiva(
            titulo: 'Confira uma dose prevista',
            explicacao:
                'Há uma próxima dose informada para $nomePet em '
                '${_dataBrasileira(proximaData)}, anterior à data de hoje. '
                'Confira o registro e a orientação do médico-veterinário.',
          ),
        );
      } else if (proximaData.compareTo(limiteIso) <= 0) {
        sugestoes.add(
          SugestaoPreventiva(
            titulo: 'Próxima dose registrada',
            explicacao:
                'Uma dose de $nomePet está registrada para '
                '${_dataBrasileira(proximaData)}. '
                'Essa data foi informada no aplicativo; confira o registro.',
          ),
        );
      }
    }

    // Regra 2: nenhum registro do tipo vacina neste aplicativo.
    final temVacina = registros.any((registro) => registro['tipo'] == 'vacina');

    if (!temVacina) {
      final nascimento = pet['data_nascimento'] as String?;
      var contextoIdade = '';

      if (nascimento != null) {
        final dataNascimento = DateTime.parse(nascimento);
        var meses =
            (hoje.year - dataNascimento.year) * 12 +
            hoje.month -
            dataNascimento.month;

        if (hoje.day < dataNascimento.day) meses--;

        if (meses >= 0) {
          contextoIdade = meses < 1
              ? ' com menos de um mês de idade'
              : ' com $meses meses de idade';
        }
      }

      final contextoEspecie = especie.isEmpty
          ? ''
          : ' ($especie$contextoIdade)';

      sugestoes.add(
        SugestaoPreventiva(
          titulo: 'Histórico de vacinação',
          explicacao:
              'Não há vacina cadastrada para $nomePet$contextoEspecie '
              'neste aplicativo. Isso não confirma ausência de vacinação; '
              'confira a carteira do pet e atualize o histórico se necessário.',
        ),
      );
    }

    // Regra 3: comparação entre dois períodos completos de sete dias.
    // Só mostramos esta regra para cães e quando há registros suficientes.
    final ehCao = {'cachorro', 'cão', 'cao', 'canino'}.contains(especie);

    if (ehCao) {
      var passeiosAnteriores = 0;
      var passeiosAtuais = 0;

      for (final passeio in passeios) {
        final ocorridoEm = DateTime.parse(passeio['ocorrido_em'] as String)
            .toLocal();

        if (ocorridoEm.isBefore(inicioAtual)) {
          passeiosAnteriores++;
        } else {
          passeiosAtuais++;
        }
      }

      if (passeiosAnteriores >= 3 && passeiosAtuais * 2 <= passeiosAnteriores) {
        sugestoes.add(
          SugestaoPreventiva(
            titulo: 'Mudança nos passeios registrados',
            explicacao:
                'Nos sete dias completos anteriores, houve '
                '$passeiosAnteriores registros de passeio de $nomePet; '
                'nos sete dias completos mais recentes, houve '
                '$passeiosAtuais. Essa comparação considera apenas '
                'o que foi registrado no aplicativo.',
          ),
        );
      }
    }

    return sugestoes;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.idPet == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sugestões Preventivas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Atualizar sugestões',
                onPressed: _atualizar,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<SugestaoPreventiva>>(
            future: _sugestoes,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  'Não foi possível carregar as sugestões. '
                  'Toque em atualizar para tentar novamente.',
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final sugestoes = snapshot.data!;

              if (sugestoes.isEmpty) {
                return const Text(
                  'Nenhuma sugestão para os registros atuais deste pet.',
                );
              }

              return Column(
                children: [
                  for (final sugestao in sugestoes)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.lightbulb_outline),
                        title: Text(sugestao.titulo),
                        subtitle: Text(sugestao.explicacao),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
