import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pet_model.dart';

class PetRepository {
  // Instancia a referência do cliente Supabase
  final _supabase = Supabase.instance.client;

  // Cadastra um novo pet
  Future<void> cadastrarPet(PetModel pet) async {
    final idTutor = _supabase.auth.currentUser?.id;

    if (idTutor == null) {
      throw StateError('É necessário entrar para cadastrar um pet.');
    }

    await _supabase.from('pet').insert({...pet.toMap(), 'id_tutor': idTutor});
  }

  // Busca o último pet cadastrado
  Future<List<PetModel>> buscarPets() async {
    final List<Map<String, dynamic>> response = await _supabase
        .from('pet')
        .select()
        .order('nome', ascending: true);

    return response.map<PetModel>((dadosPet) {
      return PetModel.fromMap(dadosPet);
    }).toList();
  }

  // Atualiza os dados de um pet existente
  Future<void> atualizarPet(PetModel pet) async {
    final idPet = pet.idPet;
    final idTutor = _supabase.auth.currentUser?.id;

    if (idPet == null || idTutor == null) {
      throw StateError('Pet ou usuário não identificado.');
    }

    final registrosAtualizados = await _supabase
        .from('pet')
        .update({
          'nome': pet.nome,
          'especie': pet.especie,
          'raca': pet.raca,
          'sexo': pet.sexo,
          'data_nascimento': pet.toMap()['data_nascimento'],
        })
        .eq('id_pet', idPet)
        .eq('id_tutor', idTutor)
        .select('id_pet');

    if (registrosAtualizados.isEmpty) {
      throw StateError(
        'Pet não encontrado ou você não tem permissão para editá-lo.',
      );
    }
  }

  Future<void> excluirPet(int idPet) async {
    final registrosExcluidos = await _supabase
        .from('pet')
        .delete()
        .eq('id_pet', idPet)
        .select('id_pet');

    if (registrosExcluidos.isEmpty) {
      throw Exception('Pet não encontrado ou exclusão não permitida.');
    }
  }

  Stream<List<PetModel>> observarPets() {
    return _supabase
        .from('pet')
        .stream(primaryKey: ['id_pet'])
        .order('nome')
        .map(
          (registros) =>
              registros.map((registro) => PetModel.fromMap(registro)).toList(),
        );
  }
}
