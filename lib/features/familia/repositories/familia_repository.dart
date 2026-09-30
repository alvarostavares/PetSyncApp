import 'package:supabase_flutter/supabase_flutter.dart';

class FamiliaRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> buscarPetsDoTutor() async {
    final idUsuario = _supabase.auth.currentUser?.id;
    if (idUsuario == null) {
      throw StateError('É necessário entrar na conta.');
    }

    final dados = await _supabase
        .from('pet')
        .select('id_pet, nome')
        .eq('id_tutor', idUsuario)
        .order('nome', ascending: true);

    return dados.map((linha) => Map<String, dynamic>.from(linha)).toList();
  }

  Future<String> criarConvite(int idPet) async {
    final resultado = await _supabase.rpc(
      'criar_convite_pet',
      params: {'p_id_pet': idPet},
    );

    return resultado as String;
  }

  Future<void> aceitarConvite(String codigo) async {
    await _supabase.rpc('aceitar_convite_pet', params: {'p_codigo': codigo});
  }

  Future<List<Map<String, dynamic>>> listarMembros(int idPet) async {
    final resultado = await _supabase.rpc(
      'listar_membros_pet',
      params: {'p_id_pet': idPet},
    );

    return (resultado as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> removerMembro(int idPet, String idUsuario) async {
    await _supabase.rpc(
      'remover_membro_pet',
      params: {'p_id_pet': idPet, 'p_id_usuario': idUsuario},
    );
  }
}
