enum TipoRegistroSaude { vacina, consulta, medicamento, outro }

extension TipoRegistroSaudeTexto on TipoRegistroSaude {
  String get rotulo => switch (this) {
    TipoRegistroSaude.vacina => 'Vacina',
    TipoRegistroSaude.consulta => 'Consulta',
    TipoRegistroSaude.medicamento => 'Medicamento',
    TipoRegistroSaude.outro => 'Outro',
  };
}

class RegistroSaudeModel {
  final int idRegistro;
  final TipoRegistroSaude tipo;
  final String titulo;
  final DateTime dataEvento;
  final DateTime? dataProximaDose;
  final String? observacoes;
  final String? criadoPor;

  const RegistroSaudeModel({
    required this.idRegistro,
    required this.tipo,
    required this.titulo,
    required this.dataEvento,
    required this.dataProximaDose,
    required this.observacoes,
    required this.criadoPor,
  });

  factory RegistroSaudeModel.fromMap(Map<String, dynamic> dados) {
    return RegistroSaudeModel(
      idRegistro: dados['id_registro'] as int,
      tipo: TipoRegistroSaude.values.byName(dados['tipo'] as String),
      titulo: dados['titulo'] as String,
      dataEvento: DateTime.parse(dados['data_evento'] as String),
      dataProximaDose: dados['data_proxima_dose'] == null
          ? null
          : DateTime.parse(dados['data_proxima_dose'] as String),
      observacoes: dados['observacoes'] as String?,
      criadoPor: dados['criado_por'] as String?,
    );
  }
}
