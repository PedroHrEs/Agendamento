class DentistModel {
  const DentistModel({
    required this.nome,
    required this.cro,
    required this.especialidade,
    required this.telefone,
    required this.img,
  });

  final String nome;
  final String cro;
  final String especialidade;
  final String telefone;
  final String img;

  factory DentistModel.fromJson(Map<String, dynamic> json) => DentistModel(
        nome: json['nome'] as String? ?? '',
        cro: json['cro'] as String? ?? '',
        especialidade: json['especialidade'] as String? ?? '',
        telefone: json['telefone'] as String? ?? '',
        img: json['img'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'nome': nome.trim(),
        'cro': cro.trim(),
        'especialidade': especialidade.trim(),
        'telefone': telefone.trim(),
        'img': img.trim(),
      };
}
