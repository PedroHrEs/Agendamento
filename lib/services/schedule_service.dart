import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/schedule.dart';

/// Acesso de baixo nível à coleção de agendamentos no Firestore.
class ScheduleService {
  ScheduleService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<ScheduleModel> get _schedules => _firestore
      .collection('schedules')
      .withConverter<ScheduleModel>(
        fromFirestore: ScheduleModel.fromFirestore,
        toFirestore: (schedule, _) => schedule.toFirestore(),
      );

  String get _currentUserId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');
    return uid;
  }

  Stream<List<ScheduleModel>> streamMySchedules() {
    final userId = _currentUserId;
    return _schedules.where('userId', isEqualTo: userId).snapshots().map((snapshot) {
      final schedules = snapshot.docs.map((doc) => doc.data()).toList();
      schedules.sort((a, b) => a.horario.compareTo(b.horario));
      return schedules;
    });
  }

  /// Retorna os horários já reservados em uma data, por todos os usuários.
  Stream<Set<int>> streamBookedHours(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    return _schedules
        .where('horario', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('horario', isLessThan: end.toIso8601String())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((document) => DateTime.tryParse(document.data().horario)?.hour)
            .whereType<int>()
            .toSet());
  }

  /// O ID calculado garante que apenas um usuário reserve cada horário.
  Future<void> createSchedule(ScheduleModel schedule) async {
    final userId = _currentUserId;
    _validateSchedule(schedule, expectedUserId: userId);
    final reference = _schedules.doc(_documentIdFor(schedule.horario));
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        throw Exception('Este horário já está agendado. Escolha outro.');
      }
      transaction.set(reference, schedule.copyWith(uid: reference.id));
    });
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    final userId = _currentUserId;
    _validateSchedule(schedule, expectedUserId: userId);
    final oldReference = _schedules.doc(schedule.uid);
    final newReference = _schedules.doc(_documentIdFor(schedule.horario));

    await _firestore.runTransaction((transaction) async {
      final oldSnapshot = await transaction.get(oldReference);
      if (!oldSnapshot.exists || oldSnapshot.data()?.userId != userId) {
        throw Exception('Agendamento não encontrado.');
      }
      if (oldReference.id != newReference.id) {
        final newSnapshot = await transaction.get(newReference);
        if (newSnapshot.exists) {
          throw Exception('Este horário já está agendado. Escolha outro.');
        }
        transaction.set(newReference, schedule.copyWith(uid: newReference.id));
        transaction.delete(oldReference);
      } else {
        transaction.update(oldReference, {
          'horario': schedule.horario,
          'patientId': schedule.patientId,
          'patientName': schedule.patientName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> deleteSchedule(String scheduleId) async {
    final userId = _currentUserId;
    final reference = _schedules.doc(scheduleId);
    final snapshot = await reference.get();
    if (!snapshot.exists || snapshot.data()?.userId != userId) {
      throw Exception('Agendamento não encontrado.');
    }
    await reference.delete();
  }

  void _validateSchedule(ScheduleModel schedule, {required String expectedUserId}) {
    if (schedule.userId != expectedUserId) {
      throw Exception('Não é permitido agendar para outro usuário.');
    }
    final dateTime = DateTime.tryParse(schedule.horario);
    if (dateTime == null ||
        dateTime.minute != 0 ||
        dateTime.second != 0 ||
        dateTime.hour < 8 ||
        dateTime.hour > 18) {
      throw Exception('Selecione um horário inteiro entre 08:00 e 18:00.');
    }
    if (dateTime.isBefore(DateTime.now())) {
      throw Exception('Não é possível agendar em um horário que já passou.');
    }
  }

  String _documentIdFor(String horario) {
    final dateTime = DateTime.parse(horario);
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}_'
        '${dateTime.hour.toString().padLeft(2, '0')}00';
  }
}
