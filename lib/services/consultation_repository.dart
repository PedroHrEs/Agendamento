import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/consultation.dart';

class ConsultationRepository {
  ConsultationRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<ConsultationModel> get _consultations => _firestore
      .collection('consultations')
      .withConverter<ConsultationModel>(
        fromFirestore: ConsultationModel.fromFirestore,
        toFirestore: (consultation, _) => consultation.toFirestore(),
      );

  Stream<List<ConsultationModel>> streamMyConsultations() {
    final userId = _userId;
    return _consultations.where('userId', isEqualTo: userId).snapshots().map((snapshot) {
      final consultations = snapshot.docs.map((document) => document.data()).toList();
      consultations.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return consultations;
    });
  }

  Future<void> create({
    required String patientId,
    required String patientName,
    required DateTime dateTime,
    required String imageUrl,
    required String description,
    required double totalValue,
  }) async {
    _validate(patientId, dateTime, imageUrl, description, totalValue);
    final reference = _consultations.doc();
    await reference.set(ConsultationModel(
      id: reference.id,
      userId: _userId,
      patientId: patientId,
      patientName: patientName,
      dateTime: dateTime,
      imageUrl: imageUrl,
      description: description,
      totalValue: totalValue,
    ));
  }

  Future<void> update(ConsultationModel consultation) async {
    if (consultation.userId != _userId) throw Exception('Consulta não encontrada.');
    _validate(
      consultation.patientId,
      consultation.dateTime,
      consultation.imageUrl,
      consultation.description,
      consultation.totalValue,
    );
    final data = consultation.toFirestore();
    // A data de criação pertence ao primeiro cadastro e não deve ser alterada.
    data.remove('createdAt');
    await _consultations.doc(consultation.id).update(data);
  }

  Future<void> delete(ConsultationModel consultation) async {
    if (consultation.userId != _userId) throw Exception('Consulta não encontrada.');
    await _consultations.doc(consultation.id).delete();
  }

  String get _userId {
    final id = _auth.currentUser?.uid;
    if (id == null) throw Exception('Usuário não autenticado.');
    return id;
  }

  void _validate(String patientId, DateTime dateTime, String imageUrl,
      String description, double totalValue) {
    if (patientId.trim().isEmpty) throw Exception('Selecione um paciente.');
    if (dateTime.year == 1970) throw Exception('Informe a data e o horário da consulta.');
    if (description.trim().isEmpty) throw Exception('Informe o que foi realizado.');
    if (!totalValue.isFinite || totalValue < 0) {
      throw Exception('Informe um valor total válido.');
    }
    final url = imageUrl.trim();
    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        throw Exception('Informe uma URL de imagem válida.');
      }
    }
  }
}
