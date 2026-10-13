import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/atividade_model.dart';

class AtividadeRepository {
  final _supabase = Supabase.instance.client;

  Future<void> registrar(
    int idPet,
    TipoAtividade tipo, {
    String? nomeMedicamento,
    String? doseInformada,
  }) async {
    final usuario = _supabase.auth.currentUser;
    final idUsuario = usuario?.id;
    final nomeAutor = usuario?.email?.split('@').first ?? 'Familiar';
    if (idUsuario == null) {
      throw StateError('Entre na sua conta para registrar uma atividade.');
    }
    if (tipo == TipoAtividade.remedio &&
        (nomeMedicamento == null || nomeMedicamento.trim().isEmpty)) {
      throw ArgumentError('Informe o nome do medicamento.');
    }

    await _supabase.from('atividade_pet').insert({
      'id_pet': idPet,
      'tipo': tipo.name,
      'criado_por': idUsuario,
      'nome_autor': nomeAutor,
      'nome_medicamento': tipo == TipoAtividade.remedio
          ? nomeMedicamento?.trim()
          : null,
      'dose_informada':
          tipo == TipoAtividade.remedio &&
              (doseInformada?.trim().isNotEmpty ?? false)
          ? doseInformada!.trim()
          : null,
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
