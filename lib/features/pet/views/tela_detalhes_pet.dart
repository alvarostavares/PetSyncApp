import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pet_model.dart';
import '../views/tela_perfil_pet.dart';
import '../repositories/pet_repository.dart';

class TelaDetalhesPet extends StatelessWidget {
  final PetModel pet;

  const TelaDetalhesPet({super.key, required this.pet});

  Future<void> _confirmarExclusao(BuildContext context) async {
    final idPet = pet.idPet;

    if (idPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este pet ainda não possui um ID.')),
      );
      return;
    }

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir pet?'),
        content: Text(
          'Deseja excluir ${pet.nome}? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!context.mounted || confirmou != true) return;

    try {
      await PetRepository().excluirPet(idPet);

      if (!context.mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir o pet: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String iconeEspecie = '🐾';
    String especieBanco = pet.especie?.toLowerCase() ?? '';
    if (especieBanco.contains('canino') || especieBanco.contains('cachorro'))
      iconeEspecie = '🐕';
    if (especieBanco.contains('felino') || especieBanco.contains('gato'))
      iconeEspecie = '🐈';

    final nomeTipoAnimal = switch (pet.especie) {
      'cachorro' => 'Cachorro',
      'gato' => 'Gato',
      'ave' => 'Ave',
      'coelho' => 'Coelho',
      'outro' => 'Outro',
      _ => 'Não informado',
    };

    final nomeSexo = switch (pet.sexo) {
      'macho' => 'Macho',
      'femea' => 'Fêmea',
      _ => 'Não informado',
    };

    final podeGerenciar =
        pet.idTutor != null &&
        pet.idTutor == Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E65F3),
        foregroundColor: Colors.white,
        title: const Text('Perfil do Pet'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (podeGerenciar)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final salvou = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TelaPerfilPet(petAtual: pet),
                  ),
                );

                if (!context.mounted || salvou != true) return;

                Navigator.pop(context, true);
              },
            ),
          if (podeGerenciar)
            IconButton(
              tooltip: 'Excluir pet',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmarExclusao(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho com o Avatar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 32, top: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF2E65F3),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      pet.nome.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 40,
                        color: Color(0xFF2E65F3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${pet.nome} $iconeEspecie',
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${pet.pontuacaoGrupo} Pontos',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Cards de Informações
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informações Gerais',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _construirCardInfo(
                    Icons.category,
                    'Tipo de animal',
                    nomeTipoAnimal,
                  ),
                  const SizedBox(height: 12),
                  _construirCardInfo(
                    Icons.auto_awesome,
                    'Raça',
                    pet.raca ?? 'Não informada',
                  ),
                  const SizedBox(height: 12),
                  _construirCardInfo(Icons.pets, 'Sexo', nomeSexo),
                  const SizedBox(height: 12),
                  _construirCardInfo(
                    Icons.cake,
                    'Data de Nascimento',
                    _formatarData(pet.dataNascimento),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirCardInfo(IconData icone, String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2E65F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: const Color(0xFF2E65F3)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatarData(DateTime? data) {
    if (data == null) return 'Não informada';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}
