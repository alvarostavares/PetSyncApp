import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/atividade_model.dart';
import '../repositories/atividade_repository.dart';

class AcoesELinhaDoTempo extends StatefulWidget {
  final int? idPet;

  const AcoesELinhaDoTempo({super.key, required this.idPet});

  @override
  State<AcoesELinhaDoTempo> createState() => _AcoesELinhaDoTempoState();
}

class _AcoesELinhaDoTempoState extends State<AcoesELinhaDoTempo> {
  final _repositorio = AtividadeRepository();

  Stream<List<AtividadeModel>>? _atividades;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _iniciarObservacao();
  }

  @override
  void didUpdateWidget(covariant AcoesELinhaDoTempo oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.idPet != widget.idPet) {
      _iniciarObservacao();
    }
  }

  void _iniciarObservacao() {
    final idPet = widget.idPet;
    _atividades = idPet == null ? null : _repositorio.observar(idPet);
  }

  String _rotulo(TipoAtividade tipo) {
    return switch (tipo) {
      TipoAtividade.alimentar => 'Alimentar',
      TipoAtividade.agua => 'Água',
      TipoAtividade.passeio => 'Passeio',
      TipoAtividade.remedio => 'Remédio',
    };
  }

  IconData _icone(TipoAtividade tipo) {
    return switch (tipo) {
      TipoAtividade.alimentar => Icons.food_bank,
      TipoAtividade.agua => Icons.water_drop,
      TipoAtividade.passeio => Icons.pets,
      TipoAtividade.remedio => Icons.medication,
    };
  }

  Future<void> _registrar(
    TipoAtividade tipo, {
    String? nomeMedicamento,
    String? doseInformada,
  }) async {
    final idPet = widget.idPet;
    if (idPet == null || _salvando) return;

    setState(() => _salvando = true);

    try {
      await _repositorio.registrar(
        idPet,
        tipo,
        nomeMedicamento: nomeMedicamento,
        doseInformada: doseInformada,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_rotulo(tipo)} registrado com sucesso.')),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível registrar: $erro')),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  Future<void> _registrarRemedio() async {
    if (widget.idPet == null || _salvando) return;

    final formKey = GlobalKey<FormState>();
    String nome = '';
    String dose = '';

    final dados = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registrar remédio'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Medicamento',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (valor) => nome = valor,
                  validator: (valor) => valor == null || valor.trim().isEmpty
                      ? 'Informe o medicamento'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Dose administrada (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (valor) => dose = valor,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;

              Navigator.pop(dialogContext, {
                'nome': nome.trim(),
                'dose': dose.trim(),
              });
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );

    if (!mounted || dados == null) return;

    await _registrar(
      TipoAtividade.remedio,
      nomeMedicamento: dados['nome'],
      doseInformada: dados['dose'],
    );
  }

  Widget _botaoAcao(
    IconData icone,
    String titulo,
    Color corFundo,
    TipoAtividade? tipo,
  ) {
    return Opacity(
      opacity: tipo == null ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: tipo == null || widget.idPet == null || _salvando
                ? null
                : () {
                    if (tipo == TipoAtividade.remedio) {
                      _registrarRemedio();
                    } else {
                      _registrar(tipo);
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: corFundo,
                    radius: 20,
                    child: Icon(icone, color: Colors.black54, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    titulo,
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final idUsuario = Supabase.instance.client.auth.currentUser?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ações Rápidas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _botaoAcao(
                  Icons.food_bank,
                  'Alimentar',
                  const Color(0xFFFBE4D8),
                  TipoAtividade.alimentar,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _botaoAcao(
                  Icons.water_drop,
                  'Água',
                  const Color(0xFFDCE8FF),
                  TipoAtividade.agua,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _botaoAcao(
                  Icons.pets,
                  'Passeio',
                  const Color(0xFFE2F5E9),
                  TipoAtividade.passeio,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _botaoAcao(
                  Icons.medication,
                  'Remédio',
                  const Color(0xFFFFE2E5),
                  TipoAtividade.remedio,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Linha do Tempo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_atividades == null)
            const Text('Selecione um pet para ver as atividades.')
          else
            StreamBuilder<List<AtividadeModel>>(
              stream: _atividades,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Não foi possível carregar as atividades.');
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final atividades = snapshot.data!;

                if (atividades.isEmpty) {
                  return const Text(
                    'Nenhuma atividade registrada para este pet.',
                  );
                }

                return Column(
                  children: [
                    for (final atividade in atividades)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(_icone(atividade.tipo)),
                        title: Text(
                          atividade.tipo == TipoAtividade.remedio
                              ? 'Remédio: ${atividade.nomeMedicamento ?? 'não informado'}'
                              : _rotulo(atividade.tipo),
                        ),
                        subtitle: Text(
                          [
                            if (atividade.tipo == TipoAtividade.remedio &&
                                atividade.doseInformada?.isNotEmpty == true)
                              'Dose informada: ${atividade.doseInformada}',
                            idUsuario != null &&
                                    atividade.criadoPor == idUsuario
                                ? 'Registrado por você'
                                : 'Registrado por ${atividade.nomeAutor?.isNotEmpty == true ? atividade.nomeAutor : 'um familiar'}',
                          ].join('\n'),
                        ),
                        trailing: Text(
                          '${MaterialLocalizations.of(context).formatShortDate(atividade.ocorridoEm)}\n'
                          '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(atividade.ocorridoEm))}',
                          textAlign: TextAlign.end,
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
