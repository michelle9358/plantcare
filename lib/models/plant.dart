class Plant {
  String? id;
  String nome;
  String especie;
  String rega;
  String iluminacao;

  Plant({
    this.id,
    required this.nome,
    required this.especie,
    required this.rega,
    required this.iluminacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'especie': especie,
      'rega': rega,
      'iluminacao': iluminacao,
    };
  }

  factory Plant.fromMap(Map<String, dynamic> map, {String? id}) {
    return Plant(
      id: id,
      nome: map['nome']?.toString() ?? '',
      especie: map['especie']?.toString() ?? 'Não informada',
      rega: map['rega']?.toString() ?? 'Não informada',
      iluminacao: map['iluminacao']?.toString() ?? 'Não informada',
    );
  }
}
