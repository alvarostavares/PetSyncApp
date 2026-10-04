import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/registro_saude_model.dart';

class RegistroSaudeRepository {
  final _supabase = Supabase.instance.client;

  Stream<List<RegistroSaudeModel>> observar(int idPet) {
    return _supabase
        .from('registro_saude')
        .stream(primaryKey: ['id_registro'])
        .eq('id_pet', idPet)
        .order('data_evento', ascending: false)
        .limit(50)
        .map(
          (registros) => registros
              .map((dados) => RegistroSaudeModel.fromMap(dados))
              .toList(),
        );
  }

  Future<void> cadastrar({
    required int idPet,
    required TipoRegistroSaude tipo,
    required String titulo,
    required DateTime dataEvento,
    String? observacoes,
  }) async {
    final idUsuario = _supabase.auth.currentUser?.id;

    if (idUsuario == null) {
      throw StateError('Entre na sua conta para registrar a saúde do pet.');
    }

    final dataBanco =
        '${dataEvento.year.toString().padLeft(4, '0')}-'
        '${dataEvento.month.toString().padLeft(2, '0')}-'
        '${dataEvento.day.toString().padLeft(2, '0')}';

    await _supabase.from('registro_saude').insert({
      'id_pet': idPet,
      'criado_por': idUsuario,
      'tipo': tipo.name,
      'titulo': titulo.trim(),
      'data_evento': dataBanco,
      'observacoes': observacoes?.trim().isEmpty == true
          ? null
          : observacoes?.trim(),
    });
  }

  Future<void> excluir({required int idPet, required int idRegistro}) async {
    final excluidos = await _supabase
        .from('registro_saude')
        .delete()
        .eq('id_registro', idRegistro)
        .eq('id_pet', idPet)
        .select('id_registro');

    if (excluidos.isEmpty) {
      throw StateError('Registro não encontrado ou exclusão não permitida.');
    }
  }
}
