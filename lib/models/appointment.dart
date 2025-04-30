class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime dateTime;
  final String status; // "scheduled", "completed", "cancelled", "no-show"
  final String? notes;

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.dateTime,
    required this.status,
    this.notes,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      status: json['status'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'dateTime': dateTime.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    String? patientName,
    DateTime? dateTime,
    String? status,
    String? notes,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
