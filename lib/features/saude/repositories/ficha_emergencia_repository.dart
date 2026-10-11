import 'package:supabase_flutter/supabase_flutter.dart';

class FichaEmergenciaRepository {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> buscar(int idPet) async {
    return _supabase
        .from('ficha_emergencia')
        .select()
        .eq('id_pet', idPet)
        .maybeSingle();
  }

  Future<void> salvar({
    required int idPet,
    required String alergias,
    required String condicoes,
    required String medicamentosUsoContinuo,
    required String veterinario,
    required String telefoneVeterinario,
    required String observacoes,
  }) async {
    String? textoOpcional(String texto) {
      final valor = texto.trim();
      return valor.isEmpty ? null : valor;
    }

    final registros = await _supabase
        .from('ficha_emergencia')
        .upsert({
          'id_pet': idPet,
          'alergias': textoOpcional(alergias),
          'condicoes': textoOpcional(condicoes),
          'medicamentos_uso_continuo': textoOpcional(medicamentosUsoContinuo),
          'veterinario': textoOpcional(veterinario),
          'telefone_veterinario': textoOpcional(telefoneVeterinario),
          'observacoes': textoOpcional(observacoes),
        }, onConflict: 'id_pet')
        .select('id_pet');

    if (registros.isEmpty) {
      throw StateError('A ficha não foi salva. Verifique seu acesso ao pet.');
    }
  }
}
