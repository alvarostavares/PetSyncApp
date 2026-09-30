class PetModel {
  final int? idPet;
  final String? idTutor;
  final String nome;
  final String? especie;
  final String? raca;
  final DateTime? dataNascimento;
  final String sexo;
  final int pontuacaoGrupo;

  PetModel({
    this.idPet,
    this.idTutor,
    required this.nome,
    this.especie,
    this.raca,
    this.dataNascimento,
    this.sexo = 'nao_informado',
    this.pontuacaoGrupo = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (idPet != null) 'id_pet': idPet,
      'nome': nome,
      'especie': especie,
      'raca': raca,
      'data_nascimento': dataNascimento?.toIso8601String().split('T')[0],
      'sexo': sexo,
      'pontuacao_grupo': pontuacaoGrupo,
    };
  }

  factory PetModel.fromMap(Map<String, dynamic> map) {
    return PetModel(
      idPet: map['id_pet'] as int?,
      idTutor: map['id_tutor'] as String?,
      nome: map['nome'] as String,
      especie: map['especie'] as String?,
      raca: map['raca'] as String?,
      dataNascimento: map['data_nascimento'] != null
          ? DateTime.parse(map['data_nascimento'] as String)
          : null,
      sexo: map['sexo'] as String? ?? 'nao_informado',
      pontuacaoGrupo: map['pontuacao_grupo'] as int? ?? 0,
    );
  }
}
