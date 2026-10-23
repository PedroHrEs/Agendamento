import 'package:cloud_firestore/cloud_firestore.dart';

/// Consulta clínica vinculada a um paciente.
class ConsultationModel {
  const ConsultationModel({
    required this.id,
    required this.userId,
    required this.patientId,
    required this.patientName,
    required this.dateTime,
    required this.description,
    required this.totalValue,
    this.imageUrl = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String patientId;
  final String patientName;
  final DateTime dateTime;
  final String imageUrl;
  final String description;
  final double totalValue;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ConsultationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return ConsultationModel(
      id: (data['id'] as String?) ?? snapshot.id,
      userId: (data['userId'] as String?) ?? '',
      patientId: (data['patientId'] as String?) ?? '',
      patientName: (data['patientName'] as String?) ?? '',
      dateTime: _dateTime(data['dateTime']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      imageUrl: (data['imageUrl'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      totalValue: (data['totalValue'] as num?)?.toDouble() ?? 0,
      createdAt: _dateTime(data['createdAt']),
      updatedAt: _dateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'userId': userId,
        'patientId': patientId,
        'patientName': patientName.trim(),
        'dateTime': Timestamp.fromDate(dateTime),
        'imageUrl': imageUrl.trim(),
        'description': description.trim(),
        'totalValue': totalValue,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  ConsultationModel copyWith({
    String? patientId,
    String? patientName,
    DateTime? dateTime,
    String? imageUrl,
    String? description,
    double? totalValue,
  }) =>
      ConsultationModel(
        id: id,
        userId: userId,
        patientId: patientId ?? this.patientId,
        patientName: patientName ?? this.patientName,
        dateTime: dateTime ?? this.dateTime,
        imageUrl: imageUrl ?? this.imageUrl,
        description: description ?? this.description,
        totalValue: totalValue ?? this.totalValue,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static DateTime? _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
