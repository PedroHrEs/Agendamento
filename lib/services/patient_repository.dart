import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/patient.dart';

class PatientRepository {
  PatientRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<PatientModel> get _patients => _firestore
      .collection('patients')
      .withConverter<PatientModel>(
        fromFirestore: PatientModel.fromFirestore,
        toFirestore: (patient, _) => patient.toFirestore(),
      );

  Stream<List<PatientModel>> streamMyPatients() {
    final userId = _userId;
    return _patients.where('userId', isEqualTo: userId).snapshots().map((snapshot) {
      final patients = snapshot.docs.map((doc) => doc.data()).toList();
      patients.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return patients;
    });
  }

  Future<void> create({
    required String name,
    required String cpf,
    required String phone,
    required String email,
    required String birthDate,
    required String address,
    required String notes,
  }) async {
    _validate(name, cpf, phone, email, birthDate);
    final reference = _patients.doc();
    await reference.set(PatientModel(
      id: reference.id,
      name: name,
      cpf: cpf,
      phone: phone,
      email: email,
      birthDate: birthDate,
      address: address,
      notes: notes,
      userId: _userId,
    ));
  }

  Future<void> update(PatientModel patient) async {
    _validate(patient.name, patient.cpf, patient.phone, patient.email, patient.birthDate);
    if (patient.userId != _userId) throw Exception('Paciente não encontrado.');
    await _patients.doc(patient.id).update(patient.toFirestore());
  }

  Future<void> delete(PatientModel patient) async {
    if (patient.userId != _userId) throw Exception('Paciente não encontrado.');
    await _patients.doc(patient.id).delete();
  }

  String get _userId {
    final id = _auth.currentUser?.uid;
    if (id == null) throw Exception('Usuário não autenticado.');
    return id;
  }

  void _validate(String name, String cpf, String phone, String email, String birthDate) {
    if (name.trim().isEmpty || cpf.trim().isEmpty || phone.trim().isEmpty || birthDate.trim().isEmpty) {
      throw Exception('Preencha nome, CPF, telefone e data de nascimento.');
    }
    if (!_isValidCpf(cpf)) throw Exception('Informe um CPF válido.');
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim())) {
      throw Exception('Informe um e-mail válido.');
    }
    if (!_isValidBirthDate(birthDate)) {
      throw Exception('Informe uma data de nascimento válida, sem datas futuras.');
    }
  }

  bool _isValidCpf(String value) {
    final cpf = value.replaceAll(RegExp(r'\D'), '');
    if (cpf.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;
    int digit(String digits) {
      var sum = 0;
      for (var index = 0; index < digits.length; index++) {
        sum += int.parse(digits[index]) * (digits.length + 1 - index);
      }
      final remainder = sum % 11;
      return remainder < 2 ? 0 : 11 - remainder;
    }
    return cpf[9] == digit(cpf.substring(0, 9)).toString() &&
        cpf[10] == digit(cpf.substring(0, 10)).toString();
  }

  bool _isValidBirthDate(String value) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value.trim());
    if (match == null) return false;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    final today = DateTime.now();
    return date.year == year && date.month == month && date.day == day &&
        !date.isAfter(DateTime(today.year, today.month, today.day));
  }
}
