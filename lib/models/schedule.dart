import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  const ScheduleModel({
    required this.uid,
    required this.horario,
    required this.userId,
    required this.patientId,
    required this.patientName,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String horario;
  final String userId;
  final String patientId;
  final String patientName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ScheduleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return ScheduleModel(
      uid: (data['uid'] as String?) ?? snapshot.id,
      horario: (data['horario'] as String?) ?? '',
      userId: (data['userId'] as String?) ?? '',
      patientId: (data['patientId'] as String?) ?? '',
      patientName: (data['patientName'] as String?) ?? '',
      createdAt: _dateTimeFromValue(data['createdAt']),
      updatedAt: _dateTimeFromValue(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'horario': horario.trim(),
      'userId': userId.trim(),
      'patientId': patientId.trim(),
      'patientName': patientName.trim(),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> data, String uid) {
    return ScheduleModel(
      uid: uid,
      horario: (data['horario'] as String?) ?? '',
      userId: (data['userId'] as String?) ?? '',
      patientId: (data['patientId'] as String?) ?? '',
      patientName: (data['patientName'] as String?) ?? '',
      createdAt: _dateTimeFromValue(data['createdAt']),
      updatedAt: _dateTimeFromValue(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'horario': horario.trim(),
      'userId': userId.trim(),
      'patientId': patientId.trim(),
      'patientName': patientName.trim(),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    };
  }

  ScheduleModel copyWith({
    String? uid,
    String? horario,
    String? userId,
    String? patientId,
    String? patientName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleModel(
      uid: uid ?? this.uid,
      horario: horario ?? this.horario,
      userId: userId ?? this.userId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _dateTimeFromValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
