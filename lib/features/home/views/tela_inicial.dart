import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../pet/models/pet_model.dart';
import '../../pet/repositories/pet_repository.dart';
import '../../pet/views/tela_perfil_pet.dart';
import '../../pet/views/tela_detalhes_pet.dart';
import '../../ajustes/views/tela_ajustes.dart';
import '../../familia/views/tela_familia.dart';
import '../widgets/acoes_e_linha_do_tempo.dart';

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  // Instancia o repositório que criamos
  final PetRepository _repositorio = PetRepository();
  StreamSubscription<List<PetModel>>? _assinaturaPets;
  String? _erroPets;
  // Agora usamos a classe PetModel em vez de um Map genérico
  List<PetModel> _pets = [];
  PetModel? _petAtual;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _observarPets();
  }

  void _observarPets() {
    _assinaturaPets = _repositorio.observarPets().listen(
      (petsEncontrados) {
        if (!mounted) return;

        PetModel? petSelecionado;

        if (petsEncontrados.isNotEmpty) {
          petSelecionado = petsEncontrados.first;

          final idPetAtual = _petAtual?.idPet;

          if (idPetAtual != null) {
            final indice = petsEncontrados.indexWhere(
              (pet) => pet.idPet == idPetAtual,
            );

            if (indice >= 0) {
              petSelecionado = petsEncontrados[indice];
            }
          }
        }

        setState(() {
          _pets = petsEncontrados;
          _petAtual = petSelecionado;
          _carregando = false;
          _erroPets = null;
        });
      },
      onError: (Object erro) {
        if (!mounted) return;

        setState(() {
          _carregando = false;
          _erroPets = 'Não foi possível acompanhar os pets: $erro';
        });
      },
    );
  }

  @override
  void dispose() {
    _assinaturaPets?.cancel();
    super.dispose();
  }

  String get _nomeDeExibicao {
    final usuario = Supabase.instance.client.auth.currentUser;
    final nome = usuario?.userMetadata?['nome'];

    if (nome is String && nome.trim().isNotEmpty) {
      return nome.trim().split(RegExp(r'\s+')).first;
    }

    final email = usuario?.email;
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'você';
  }

  bool _souTutor(PetModel pet) {
    final meuId = Supabase.instance.client.auth.currentUser?.id;
    return meuId != null && pet.idTutor == meuId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erroPets != null
          ? Center(child: Text(_erroPets!))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _construirCabecalhoCorpo(),
                  const SizedBox(height: 20),
                  if (_petAtual != null) _construirDicaPreditiva(),
                  const SizedBox(height: 24),
                  AcoesELinhaDoTempo(idPet: _petAtual?.idPet),
                ],
              ),
            ),
      bottomNavigationBar: _construirBarraNavegacao(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const TelaPerfilPet()),
          );
        },
        backgroundColor: const Color(0xFF2E65F3),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _construirCabecalhoCorpo() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF2E65F3),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                // ADICIONADO: Expanded para evitar overflow
                child: Text(
                  'Olá, $_nomeDeExibicao! 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow
                      .ellipsis, // Coloca "..." se o nome for muito grande
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '450 pts',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Seus pets e compartilhamentos',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),

          if (_pets.isNotEmpty) ...[
            _construirSeletorPet(),
            const SizedBox(height: 16),
          ],

          _petAtual == null
              ? const Text(
                  'Nenhum pet cadastrado.',
                  style: TextStyle(color: Colors.white),
                )
              : _construirCardPet(),
        ],
      ),
    );
  }

  Widget _construirSeletorPet() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PetModel>(
          value: _petAtual,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2E65F3)),
          items: _pets.map((pet) {
            return DropdownMenuItem<PetModel>(
              value: pet,
              child: Row(
                children: [
                  const Icon(Icons.pets, color: Color(0xFF2E65F3)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pet.nome,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _souTutor(pet) ? 'Tutor' : 'Convidado',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF2E65F3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (PetModel? petSelecionado) {
            if (petSelecionado == null) return;

            setState(() {
              _petAtual = petSelecionado;
            });
          },
        ),
      ),
    );
  }

  Widget _construirCardPet() {
    String iconeEspecie = '🐾';
    String especieBanco = _petAtual!.especie?.toLowerCase() ?? '';

    if (especieBanco.contains('canino') || especieBanco.contains('cachorro'))
      iconeEspecie = '🐕';
    if (especieBanco.contains('felino') || especieBanco.contains('gato'))
      iconeEspecie = '🐈';

    return InkWell(
      // ADICIONADO: Envolvemos o card com InkWell para detectar cliques
      onTap: () async {
        await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => TelaDetalhesPet(pet: _petAtual!),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Text(
                _petAtual!.nome.isNotEmpty
                    ? _petAtual!.nome.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Color(0xFF2E65F3),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_petAtual!.nome} $iconeEspecie',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _petAtual!.raca ?? 'Raça não informada',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _souTutor(_petAtual!)
                          ? 'Você é o tutor'
                          : 'Compartilhado com você',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 16,
            ), // Ícone alterado para indicar navegação
          ],
        ),
      ),
    );
  }

  Widget _construirDicaPreditiva() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E6),
          borderRadius: BorderRadius.circular(12),
          border: const Border(left: BorderSide(color: Colors.amber, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Dica Preditiva (${_petAtual!.raca ?? 'Geral'})',
                  style: const TextStyle(
                    color: Color(0xFFB07D00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Mantenha as vacinas e a hidratação em dia para garantir o bem-estar do seu pet.',
              style: TextStyle(color: Color(0xFF8C6300), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirBarraNavegacao() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _iconeBarra(Icons.home, 'Início', true),
            InkWell(
              onTap: () async {
                final aceitouConvite = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaFamilia()),
                );

                if (!mounted || aceitouConvite != true) return;

                await _assinaturaPets?.cancel();
                if (!mounted) return;

                _observarPets();
              },
              child: _iconeBarra(Icons.people, 'Família', false),
            ),
            const SizedBox(width: 40),
            _iconeBarra(Icons.health_and_safety, 'Saúde', false),
            InkWell(
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaAjustes()),
                );
              },
              child: _iconeBarra(Icons.settings, 'Ajustes', false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconeBarra(IconData icone, String label, bool ativo) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, color: ativo ? const Color(0xFF2E65F3) : Colors.grey),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: ativo ? const Color(0xFF2E65F3) : Colors.grey,
          ),
        ),
      ],
    );
  }
}
