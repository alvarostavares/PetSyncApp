import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/lembrete_medicamento_repository.dart';

class LembretesMedicamento extends StatefulWidget {
  final int idPet;
  final bool compacto;
  final bool souTutor;

  const LembretesMedicamento({
    super.key,
    required this.idPet,
    this.compacto = false,
    this.souTutor = false,
  });

  @override
  State<LembretesMedicamento> createState() => _LembretesMedicamentoState();
}

class _LembretesMedicamentoState extends State<LembretesMedicamento> {
  final _repositorio = LembreteMedicamentoRepository();

  late Stream<List<Map<String, dynamic>>> _lembretes;
  late Stream<List<Map<String, dynamic>>> _confirmacoes;
  late String _dia;
  Timer? _relogio;
  bool _salvando = false;

  String _hoje() {
    final agora = DateTime.now();
    return '${agora.year.toString().padLeft(4, '0')}-'
        '${agora.month.toString().padLeft(2, '0')}-'
        '${agora.day.toString().padLeft(2, '0')}';
  }

  void _observar() {
    _dia = _hoje();
    _lembretes = _repositorio.observarLembretes(widget.idPet);
    _confirmacoes = _repositorio.observarConfirmacoes(widget.idPet, _dia);
  }

  @override
  void initState() {
    super.initState();
    _observar();

    _relogio = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && _dia != _hoje()) {
        setState(_observar);
      }
    });
  }

  @override
  void didUpdateWidget(covariant LembretesMedicamento oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.idPet != widget.idPet) {
      _observar();
    }
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  Future<void> _criar() async {
    String nome = '';
    TimeOfDay? horarioEscolhido;

    final dados = await showDialog<({String nome, TimeOfDay horario})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, atualizarDialogo) => AlertDialog(
          title: const Text('Lembrete diário'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                maxLength: 120,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome do medicamento',
                  border: OutlineInputBorder(),
                ),
                onChanged: (valor) {
                  atualizarDialogo(() => nome = valor);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.schedule),
                label: Text(
                  horarioEscolhido == null
                      ? 'Escolher horário'
                      : 'Horário: ${horarioEscolhido!.format(dialogContext)}',
                ),
                onPressed: () async {
                  final horario = await showTimePicker(
                    context: dialogContext,
                    initialTime: horarioEscolhido ?? TimeOfDay.now(),
                  );

                  if (!dialogContext.mounted || horario == null) return;

                  atualizarDialogo(() => horarioEscolhido = horario);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: nome.trim().isEmpty || horarioEscolhido == null
                  ? null
                  : () => Navigator.pop(dialogContext, (
                      nome: nome.trim(),
                      horario: horarioEscolhido!,
                    )),
              child: const Text('Criar lembrete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || dados == null) return;

    final horario =
        '${dados.horario.hour.toString().padLeft(2, '0')}:'
        '${dados.horario.minute.toString().padLeft(2, '0')}:00';

    setState(() => _salvando = true);

    try {
      await _repositorio.criar(
        idPet: widget.idPet,
        nome: dados.nome,
        horario: horario,
      );
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível criar: $erro')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _confirmar(int idLembrete, String nome) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar administração?'),
        content: Text('Confirme somente se $nome já foi administrado hoje.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (!mounted || confirmou != true) return;

    setState(() => _salvando = true);

    try {
      await _repositorio.confirmar(idPet: widget.idPet, idLembrete: idLembrete);
    } on PostgrestException catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              erro.code == '23505'
                  ? 'Este horário já foi confirmado hoje.'
                  : 'Não foi possível confirmar: ${erro.message}',
            ),
          ),
        );
      }
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível confirmar: $erro')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _desativar(int idLembrete) async {
    setState(() => _salvando = true);

    try {
      await _repositorio.desativar(idLembrete);
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível desativar: $erro')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final idUsuario = Supabase.instance.client.auth.currentUser?.id;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _lembretes,
      builder: (context, snapshotLembretes) {
        if (snapshotLembretes.hasError) {
          return const Text('Não foi possível carregar os remédios.');
        }

        final lembretes = snapshotLembretes.data;
        if (lembretes == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _confirmacoes,
          builder: (context, snapshotConfirmacoes) {
            if (snapshotConfirmacoes.hasError) {
              return const Text('Não foi possível carregar as confirmações.');
            }

            final confirmacoes = snapshotConfirmacoes.data;
            if (confirmacoes == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final idsConfirmados = {
              for (final registro in confirmacoes)
                registro['id_lembrete'] as int,
            };

            if (widget.compacto) {
              if (lembretes.isEmpty) {
                return const SizedBox.shrink();
              }

              final pendentes = lembretes.where(
                (item) => !idsConfirmados.contains(item['id_lembrete'] as int),
              );

              final mensagem = pendentes.isEmpty
                  ? 'Todos os horários de hoje foram confirmados.'
                  : 'Hoje, ${(pendentes.first['horario'] as String).substring(0, 5)}: '
                        '${pendentes.first['nome']}';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.medication_outlined),
                    title: const Text('Lembretes de remédio'),
                    subtitle: Text(mensagem),
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Remédios diários',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Configure horários de Maceió. '
                  'Confirme cada administração depois que acontecer.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _salvando ? null : _criar,
                  icon: const Icon(Icons.add_alert_outlined),
                  label: const Text('Criar lembrete diário'),
                ),
                if (lembretes.isEmpty)
                  const Text('Nenhum lembrete diário configurado.'),
                for (final lembrete in lembretes)
                  Card(
                    child: ListTile(
                      title: Text(lembrete['nome'] as String),
                      subtitle: Text(
                        '${(lembrete['horario'] as String).substring(0, 5)}'
                        ' • ${idsConfirmados.contains(lembrete['id_lembrete'] as int) ? 'Confirmado hoje' : 'Pendente hoje'}',
                      ),
                      trailing: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (!idsConfirmados.contains(
                            lembrete['id_lembrete'] as int,
                          ))
                            TextButton(
                              onPressed: _salvando
                                  ? null
                                  : () => _confirmar(
                                      lembrete['id_lembrete'] as int,
                                      lembrete['nome'] as String,
                                    ),
                              child: const Text('Confirmar'),
                            ),
                          if (widget.souTutor ||
                              lembrete['criado_por'] == idUsuario)
                            IconButton(
                              tooltip: 'Desativar lembrete',
                              onPressed: _salvando
                                  ? null
                                  : () => _desativar(
                                      lembrete['id_lembrete'] as int,
                                    ),
                              icon: const Icon(
                                Icons.notifications_off_outlined,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
