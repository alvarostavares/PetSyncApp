import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/registro_saude_model.dart';
import '../repositories/registro_saude_repository.dart';
import '../views/tela_ficha_emergencia.dart';

class TelaSaude extends StatefulWidget {
  final int idPet;
  final String nomePet;
  final bool souTutor;

  const TelaSaude({
    super.key,
    required this.idPet,
    required this.nomePet,
    required this.souTutor,
  });

  @override
  State<TelaSaude> createState() => _TelaSaudeState();
}

class _TelaSaudeState extends State<TelaSaude> {
  final _repositorio = RegistroSaudeRepository();
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _observacoesController = TextEditingController();

  late Stream<List<RegistroSaudeModel>> _registros;

  TipoRegistroSaude _tipo = TipoRegistroSaude.vacina;
  DateTime _dataEvento = DateTime.now();
  DateTime? _dataProximaDose;
  bool _mostrarFormulario = false;
  bool _salvando = false;
  int? _idExcluindo;

  @override
  void initState() {
    super.initState();
    _registros = _repositorio.observar(widget.idPet);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataEvento,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (!mounted || dataEscolhida == null) return;

    setState(() {
      _dataEvento = dataEscolhida;

      if (_dataProximaDose != null &&
          !_dataProximaDose!.isAfter(dataEscolhida)) {
        _dataProximaDose = null;
      }
    });
  }

  Future<void> _selecionarProximaDose() async {
    final primeiraData = DateTime(
      _dataEvento.year,
      _dataEvento.month,
      _dataEvento.day + 1,
    );

    final hoje = DateUtils.dateOnly(DateTime.now());
    final dataInicial =
        _dataProximaDose ?? (hoje.isAfter(primeiraData) ? hoje : primeiraData);

    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: primeiraData,
      lastDate: DateTime(2100, 12, 31),
    );

    if (!mounted || dataEscolhida == null) return;

    setState(() => _dataProximaDose = dataEscolhida);
  }

  bool _permiteProximaDose(TipoRegistroSaude tipo) {
    return tipo == TipoRegistroSaude.vacina ||
        tipo == TipoRegistroSaude.vermifugacao;
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _salvando = true);

    try {
      await _repositorio.cadastrar(
        idPet: widget.idPet,
        tipo: _tipo,
        titulo: _tituloController.text,
        dataEvento: _dataEvento,
        dataProximaDose: _permiteProximaDose(_tipo) ? _dataProximaDose : null,
        observacoes: _observacoesController.text,
      );

      if (!mounted) return;

      _tituloController.clear();
      _observacoesController.clear();

      setState(() {
        _mostrarFormulario = false;
        _tipo = TipoRegistroSaude.vacina;
        _dataEvento = DateTime.now();
        _dataProximaDose = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registro de saúde salvo.')));
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Não foi possível salvar: $erro')));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _tentarNovamente() async {
    try {
      final auth = Supabase.instance.client.auth;

      if (auth.currentSession?.isExpired == true) {
        await auth.refreshSession();
      }

      if (!mounted) return;
      setState(() => _registros = _repositorio.observar(widget.idPet));
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível reconectar: $erro')),
      );
    }
  }

  Future<void> _excluirRegistro(RegistroSaudeModel registro) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir registro?'),
        content: Text('Deseja excluir "${registro.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (!mounted || confirmou != true) return;

    setState(() => _idExcluindo = registro.idRegistro);

    try {
      await _repositorio.excluir(
        idPet: widget.idPet,
        idRegistro: registro.idRegistro,
      );

      if (!mounted) return;

      // Garante que esta tela atualize mesmo se o evento DELETE atrasar.
      setState(() {
        _registros = _repositorio.observar(widget.idPet);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Registro excluído.')));
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir: $erro')),
      );
    } finally {
      if (mounted) setState(() => _idExcluindo = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final idUsuario = Supabase.instance.client.auth.currentUser?.id;
    final formatoData = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Saúde de ${widget.nomePet}'),
        backgroundColor: const Color(0xFF2E65F3),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TelaFichaEmergencia(
                      idPet: widget.idPet,
                      nomePet: widget.nomePet,
                      souTutor: widget.souTutor,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.health_and_safety_outlined),
              label: const Text('Ficha de emergência'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _salvando
                  ? null
                  : () => setState(
                      () => _mostrarFormulario = !_mostrarFormulario,
                    ),
              icon: Icon(_mostrarFormulario ? Icons.close : Icons.add),
              label: Text(
                _mostrarFormulario ? 'Fechar formulário' : 'Novo registro',
              ),
            ),

            if (_mostrarFormulario) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<TipoRegistroSaude>(
                          initialValue: _tipo,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (final tipo in TipoRegistroSaude.values)
                              DropdownMenuItem(
                                value: tipo,
                                child: Text(tipo.rotulo),
                              ),
                          ],
                          onChanged: _salvando
                              ? null
                              : (tipo) {
                                  if (tipo != null) {
                                    setState(() {
                                      _tipo = tipo;
                                      if (!_permiteProximaDose(tipo)) {
                                        _dataProximaDose = null;
                                      }
                                    });
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _tituloController,
                          maxLength: 120,
                          decoration: const InputDecoration(
                            labelText: 'Título',
                            hintText: 'Ex.: Vacina antirrábica',
                            border: OutlineInputBorder(),
                          ),
                          validator: (valor) =>
                              valor == null || valor.trim().isEmpty
                              ? 'Informe um título'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _salvando ? null : _selecionarData,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            'Data: ${formatoData.formatShortDate(_dataEvento)}',
                          ),
                        ),
                        if (_permiteProximaDose(_tipo)) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _salvando
                                ? null
                                : _selecionarProximaDose,
                            icon: const Icon(Icons.event),
                            label: Text(
                              _dataProximaDose == null
                                  ? 'Definir próxima dose (opcional)'
                                  : 'Próxima dose: ${formatoData.formatShortDate(_dataProximaDose!)}',
                            ),
                          ),
                          if (_dataProximaDose != null)
                            TextButton(
                              onPressed: _salvando
                                  ? null
                                  : () =>
                                        setState(() => _dataProximaDose = null),
                              child: const Text('Remover próxima dose'),
                            ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _observacoesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Observações (opcional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _salvando ? null : _salvar,
                          child: Text(
                            _salvando ? 'Salvando...' : 'Salvar registro',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Text(
              'Histórico de saúde',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            StreamBuilder<List<RegistroSaudeModel>>(
              stream: _registros,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Column(
                    children: [
                      const Text('Não foi possível carregar os registros.'),
                      TextButton(
                        onPressed: _tentarNovamente,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final registros = snapshot.data!;

                if (registros.isEmpty) {
                  return const Text('Nenhum registro de saúde para este pet.');
                }

                return Column(
                  children: [
                    for (final registro in registros)
                      Card(
                        child: ListTile(
                          title: Text(registro.titulo),
                          subtitle: Text(
                            '${registro.tipo.rotulo} • '
                            '${formatoData.formatShortDate(registro.dataEvento)}'
                            '${registro.observacoes?.isNotEmpty == true ? '\n${registro.observacoes}' : ''}'
                            '${registro.dataProximaDose == null ? '' : '\nPróxima dose: ${formatoData.formatShortDate(registro.dataProximaDose!)}'}'
                            '\nRegistrado por ${registro.criadoPor == idUsuario ? 'você' : (registro.nomeAutor?.isNotEmpty == true ? registro.nomeAutor! : 'um familiar')}',
                          ),
                          trailing:
                              widget.souTutor ||
                                  (idUsuario != null &&
                                      registro.criadoPor == idUsuario)
                              ? IconButton(
                                  tooltip: 'Excluir registro',
                                  onPressed: _idExcluindo != null
                                      ? null
                                      : () => _excluirRegistro(registro),
                                  icon: _idExcluindo == registro.idRegistro
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.delete_outline),
                                )
                              : null,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
