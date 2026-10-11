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
    DateTime? dataProximaDose,
    String? observacoes,
  }) async {
    final usuario = _supabase.auth.currentUser;
    final idUsuario = usuario?.id;
    final nomeAutor = usuario?.email?.split('@').first ?? 'Familiar';
    if (idUsuario == null) {
      throw StateError('Entre na sua conta para registrar a saúde do pet.');
    }
    String formatarData(DateTime data) {
      return '${data.year.toString().padLeft(4, '0')}-'
          '${data.month.toString().padLeft(2, '0')}-'
          '${data.day.toString().padLeft(2, '0')}';
    }

    final dataBanco = formatarData(dataEvento);

    await _supabase.from('registro_saude').insert({
      'id_pet': idPet,
      'nome_autor': nomeAutor,
      'criado_por': idUsuario,
      'tipo': tipo.name,
      'titulo': titulo.trim(),
      'data_evento': dataBanco,
      'data_proxima_dose': dataProximaDose == null
          ? null
          : formatarData(dataProximaDose),
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
