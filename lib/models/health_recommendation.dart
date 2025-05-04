class HealthRecommendation {
  final int? id;
  final String title;
  final String description;
  final String category;
  final DateTime createdAt;
  final String? patientId;
  final bool isRead;

  HealthRecommendation({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.createdAt,
    this.patientId,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'patient_id': patientId,
      'is_read': isRead ? 1 : 0,
    };
  }

  factory HealthRecommendation.fromMap(Map<String, dynamic> map) {
    return HealthRecommendation(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      category: map['category'],
      createdAt: DateTime.parse(map['created_at']),
      patientId: map['patient_id'],
      isRead: map['is_read'] == 1,
    );
  }
} 