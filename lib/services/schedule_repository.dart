import 'package:firebase_auth/firebase_auth.dart';

import '../models/schedule.dart';
import 'schedule_service.dart';

/// Repositório usado pelas telas para executar o CRUD de agendamentos.
class ScheduleRepository {
  ScheduleRepository({ScheduleService? service, FirebaseAuth? auth})
      : _service = service ?? ScheduleService(),
        _auth = auth ?? FirebaseAuth.instance;

  final ScheduleService _service;
  final FirebaseAuth _auth;

  Stream<List<ScheduleModel>> streamMySchedules() => _service.streamMySchedules();

  Stream<Set<int>> streamBookedHours(DateTime date) =>
      _service.streamBookedHours(date);

  Future<void> create({
    required DateTime dateTime,
    required String patientId,
    required String patientName,
  }) async {
    final userId = _requireUserId();
    await _service.createSchedule(
      ScheduleModel(
        uid: '',
        horario: dateTime.toIso8601String(),
        userId: userId,
        patientId: patientId,
        patientName: patientName,
      ),
    );
  }

  Future<void> update({
    required ScheduleModel schedule,
    required DateTime dateTime,
    required String patientId,
    required String patientName,
  }) {
    return _service.updateSchedule(
      schedule.copyWith(
        horario: dateTime.toIso8601String(),
        patientId: patientId,
        patientName: patientName,
      ),
    );
  }

  Future<void> delete(ScheduleModel schedule) => _service.deleteSchedule(schedule.uid);

  String _requireUserId() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');
    return uid;
  }
}
