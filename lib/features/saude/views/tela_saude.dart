import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/registro_saude_model.dart';
import '../repositories/registro_saude_repository.dart';

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

    setState(() => _dataEvento = dataEscolhida);
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
        observacoes: _observacoesController.text,
      );

      if (!mounted) return;

      _tituloController.clear();
      _observacoesController.clear();

      setState(() {
        _mostrarFormulario = false;
        _tipo = TipoRegistroSaude.vacina;
        _dataEvento = DateTime.now();
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
                                    setState(() => _tipo = tipo);
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
                            '\n${registro.criadoPor == idUsuario ? 'Registrado por você' : 'Registrado por um familiar'}',
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
