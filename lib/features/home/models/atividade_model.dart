enum TipoAtividade { alimentar, agua, passeio, remedio }

class AtividadeModel {
  final int idAtividade;
  final TipoAtividade tipo;
  final DateTime ocorridoEm;
  final String? criadoPor;
  final String? nomeAutor;
  final String? nomeMedicamento;
  final String? doseInformada;

  const AtividadeModel({
    required this.idAtividade,
    required this.tipo,
    required this.ocorridoEm,
    required this.criadoPor,
    required this.nomeAutor,
    this.nomeMedicamento,
    this.doseInformada,
  });

  factory AtividadeModel.fromMap(Map<String, dynamic> dados) {
    return AtividadeModel(
      idAtividade: dados['id_atividade'] as int,
      tipo: TipoAtividade.values.byName(dados['tipo'] as String),
      ocorridoEm: DateTime.parse(dados['ocorrido_em'] as String).toLocal(),
      criadoPor: dados['criado_por'] as String?,
      nomeAutor: dados['nome_autor'] as String?,
      nomeMedicamento: dados['nome_medicamento'] as String?,
      doseInformada: dados['dose_informada'] as String?,
    );
  }
}
