import 'package:supabase_flutter/supabase_flutter.dart';

class LembreteMedicamentoRepository {
  final _supabase = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> observarLembretes(int idPet) {
    return _supabase
        .from('lembrete_medicamento')
        .stream(primaryKey: ['id_lembrete'])
        .eq('id_pet', idPet)
        .eq('ativo', true)
        .order('horario');
  }

  Stream<List<Map<String, dynamic>>> observarConfirmacoes(
    int idPet,
    String dia,
  ) {
    return _supabase
        .from('confirmacao_medicamento')
        .stream(primaryKey: ['id_confirmacao'])
        .eq('id_pet', idPet)
        .eq('dia', dia);
  }

  Future<void> criar({
    required int idPet,
    required String nome,
    required String horario,
  }) async {
    await _supabase.from('lembrete_medicamento').insert({
      'id_pet': idPet,
      'nome': nome.trim(),
      'horario': horario,
    });
  }

  Future<void> confirmar({required int idPet, required int idLembrete}) async {
    await _supabase.from('confirmacao_medicamento').insert({
      'id_pet': idPet,
      'id_lembrete': idLembrete,
    });
  }

  Future<void> desativar(int idLembrete) async {
    final alterados = await _supabase
        .from('lembrete_medicamento')
        .update({'ativo': false})
        .eq('id_lembrete', idLembrete)
        .select('id_lembrete');

    if (alterados.isEmpty) {
      throw StateError('Você não pode desativar este lembrete.');
    }
  }
}
