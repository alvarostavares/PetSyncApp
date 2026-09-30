import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/atividade_model.dart';

class AtividadeRepository {
  final _supabase = Supabase.instance.client;

  Future<void> registrar(int idPet, TipoAtividade tipo) async {
    final idUsuario = _supabase.auth.currentUser?.id;

    if (idUsuario == null) {
      throw StateError('Entre na sua conta para registrar uma atividade.');
    }

    await _supabase.from('atividade_pet').insert({
      'id_pet': idPet,
      'tipo': tipo.name,
      'criado_por': idUsuario,
    });
  }

  Stream<List<AtividadeModel>> observar(int idPet) {
    return _supabase
        .from('atividade_pet')
        .stream(primaryKey: ['id_atividade'])
        .eq('id_pet', idPet)
        .order('ocorrido_em', ascending: false)
        .limit(20)
        .map(
          (registros) => registros
              .map((registro) => AtividadeModel.fromMap(registro))
              .toList(),
        );
  }
}
