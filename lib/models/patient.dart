import 'package:cloud_firestore/cloud_firestore.dart';

/// Paciente atendido pela clínica.
/// A entidade possui 8 atributos de negócio: id, nome, CPF, telefone,
/// e-mail, data de nascimento, endereço e observações, além do usuário dono.
class PatientModel {
  const PatientModel({
    required this.id,
    required this.name,
    required this.cpf,
    required this.phone,
    required this.email,
    required this.birthDate,
    required this.address,
    required this.notes,
    required this.userId,
  });

  final String id;
  final String name;
  final String cpf;
  final String phone;
  final String email;
  final String birthDate;
  final String address;
  final String notes;
  final String userId;

  factory PatientModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return PatientModel(
      id: snapshot.id,
      name: (data['name'] as String?) ?? '',
      cpf: (data['cpf'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      birthDate: (data['birthDate'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      notes: (data['notes'] as String?) ?? '',
      userId: (data['userId'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name.trim(),
        'cpf': cpf.trim(),
        'phone': phone.replaceAll(RegExp(r'\D'), ''),
        'email': email.trim(),
        'birthDate': birthDate.trim(),
        'address': address.trim(),
        'notes': notes.trim(),
        'userId': userId,
      };

  PatientModel copyWith({
    String? name,
    String? cpf,
    String? phone,
    String? email,
    String? birthDate,
    String? address,
    String? notes,
  }) =>
      PatientModel(
        id: id,
        name: name ?? this.name,
        cpf: cpf ?? this.cpf,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        birthDate: birthDate ?? this.birthDate,
        address: address ?? this.address,
        notes: notes ?? this.notes,
        userId: userId,
      );
}
