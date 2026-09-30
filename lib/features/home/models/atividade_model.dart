enum TipoAtividade { alimentar, agua, passeio }

class AtividadeModel {
  final int idAtividade;
  final TipoAtividade tipo;
  final DateTime ocorridoEm;
  final String? criadoPor;

  const AtividadeModel({
    required this.idAtividade,
    required this.tipo,
    required this.ocorridoEm,
    required this.criadoPor,
  });

  factory AtividadeModel.fromMap(Map<String, dynamic> dados) {
    return AtividadeModel(
      idAtividade: dados['id_atividade'] as int,
      tipo: TipoAtividade.values.byName(dados['tipo'] as String),
      ocorridoEm: DateTime.parse(dados['ocorrido_em'] as String).toLocal(),
      criadoPor: dados['criado_por'] as String?,
    );
  }
}
