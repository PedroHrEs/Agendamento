import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  const ScheduleModel({
    required this.uid,
    required this.horario,
    required this.userId,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String horario;
  final String userId;
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
      createdAt: _dateTimeFromValue(data['createdAt']),
      updatedAt: _dateTimeFromValue(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'horario': horario.trim(),
      'userId': userId.trim(),
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
      createdAt: _dateTimeFromValue(data['createdAt']),
      updatedAt: _dateTimeFromValue(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'horario': horario.trim(),
      'userId': userId.trim(),
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleModel(
      uid: uid ?? this.uid,
      horario: horario ?? this.horario,
      userId: userId ?? this.userId,
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