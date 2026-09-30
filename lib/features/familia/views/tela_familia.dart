import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../repositories/familia_repository.dart';

class TelaFamilia extends StatefulWidget {
  const TelaFamilia({super.key});

  @override
  State<TelaFamilia> createState() => _TelaFamiliaState();
}

class _TelaFamiliaState extends State<TelaFamilia> {
  final _repositorio = FamiliaRepository();
  final _codigoController = TextEditingController();

  late final Future<List<Map<String, dynamic>>> _meusPets;

  int? _petGerandoConvite;
  bool _aceitandoConvite = false;
  String? _codigoGerado;
  String? _nomePetConvidado;

  final Map<int, Future<List<Map<String, dynamic>>>> _membrosPorPet = {};
  bool _removendoMembro = false;

  @override
  void initState() {
    super.initState();
    _meusPets = _repositorio.buscarPetsDoTutor();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _gerarConvite(int idPet, String nomePet) async {
    setState(() => _petGerandoConvite = idPet);

    try {
      final codigo = await _repositorio.criarConvite(idPet);
      if (!mounted) return;

      setState(() {
        _codigoGerado = codigo;
        _nomePetConvidado = nomePet;
      });
    } catch (erro) {
      if (mounted) _mostrarMensagem('Não foi possível gerar o convite: $erro');
    } finally {
      if (mounted) setState(() => _petGerandoConvite = null);
    }
  }

  Future<void> _aceitarConvite() async {
    final codigo = _codigoController.text.trim();

    if (codigo.isEmpty) {
      _mostrarMensagem('Insira o código recebido.');
      return;
    }

    setState(() => _aceitandoConvite = true);

    try {
      await _repositorio.aceitarConvite(codigo);
      if (!mounted) return;

      // Informa à tela anterior que ela precisa atualizar os pets.
      Navigator.pop(context, true);
    } catch (erro) {
      if (!mounted) return;

      setState(() => _aceitandoConvite = false);
      _mostrarMensagem('Não foi possível aceitar o convite: $erro');
    }
  }

  Future<List<Map<String, dynamic>>> _membrosDoPet(int idPet) {
    return _membrosPorPet.putIfAbsent(
      idPet,
      () => _repositorio.listarMembros(idPet),
    );
  }

  Future<void> _confirmarRemocao(
    int idPet,
    String idUsuario,
    String email,
  ) async {
    if (_removendoMembro) return;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover participante?'),
        content: Text('$email perderá o acesso a este pet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (!mounted || confirmou != true) return;

    setState(() => _removendoMembro = true);

    try {
      await _repositorio.removerMembro(idPet, idUsuario);
      if (!mounted) return;

      setState(() {
        _removendoMembro = false;
        _membrosPorPet[idPet] = _repositorio.listarMembros(idPet);
      });

      _mostrarMensagem('Acesso removido.');
    } catch (erro) {
      if (!mounted) return;

      setState(() => _removendoMembro = false);
      _mostrarMensagem('Não foi possível remover o acesso: $erro');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Família'),
        backgroundColor: const Color(0xFF2E65F3),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Convidar alguém',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Escolha um pet para gerar um código de convite.'),
          const SizedBox(height: 16),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: _meusPets,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Text('Erro ao carregar pets: ${snapshot.error}');
              }

              final pets = snapshot.data ?? [];

              if (pets.isEmpty) {
                return const Text('Você ainda não cadastrou um pet.');
              }

              return Column(
                children: [
                  for (final pet in pets)
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.pets),
                            title: Text(pet['nome'] as String),
                            trailing: TextButton(
                              onPressed: _petGerandoConvite == null
                                  ? () => _gerarConvite(
                                      pet['id_pet'] as int,
                                      pet['nome'] as String,
                                    )
                                  : null,
                              child: Text(
                                _petGerandoConvite == pet['id_pet']
                                    ? 'Gerando...'
                                    : 'Convidar',
                              ),
                            ),
                          ),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _membrosDoPet(pet['id_pet'] as int),
                            builder: (context, snapshotMembros) {
                              if (snapshotMembros.connectionState !=
                                  ConnectionState.done) {
                                return const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snapshotMembros.hasError) {
                                return Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    'Não foi possível carregar os participantes: '
                                    '${snapshotMembros.error}',
                                  ),
                                );
                              }

                              final membros = snapshotMembros.data ?? [];

                              if (membros.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('Nenhum participante convidado.'),
                                );
                              }

                              return Column(
                                children: [
                                  for (final membro in membros)
                                    ListTile(
                                      leading: const Icon(Icons.person_outline),
                                      title: Text(
                                        membro['email'] as String? ??
                                            'Conta sem e-mail',
                                      ),
                                      subtitle: const Text('Convidado'),
                                      trailing: IconButton(
                                        tooltip: 'Remover acesso',
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        onPressed: _removendoMembro
                                            ? null
                                            : () => _confirmarRemocao(
                                                pet['id_pet'] as int,
                                                membro['id_usuario'] as String,
                                                membro['email'] as String? ??
                                                    'Esta pessoa',
                                              ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),

          if (_codigoGerado != null) ...[
            const SizedBox(height: 16),
            Text('Convite para $_nomePetConvidado:'),
            const SizedBox(height: 8),
            SelectableText(_codigoGerado!),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _codigoGerado!));
                if (mounted) _mostrarMensagem('Código copiado.');
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar código'),
            ),
            const Text('O código vale por 7 dias e só pode ser usado uma vez.'),
          ],

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          const Text(
            'Aceitar um convite',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codigoController,
            decoration: const InputDecoration(
              labelText: 'Código recebido',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _aceitandoConvite ? null : _aceitarConvite,
            child: Text(_aceitandoConvite ? 'Aceitando...' : 'Aceitar convite'),
          ),
        ],
      ),
    );
  }
}
