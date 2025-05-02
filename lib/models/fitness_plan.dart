class FitnessPlan {
  final String id;
  final String title;
  final String description;
  final List<String> sportIds;
  final DateTime startDate;
  final DateTime endDate;
  final int targetDuration; // in minutes per week
  final bool isCompleted;

  FitnessPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.sportIds,
    required this.startDate,
    required this.endDate,
    required this.targetDuration,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'sportIds': sportIds.join(','),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'targetDuration': targetDuration,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory FitnessPlan.fromMap(Map<String, dynamic> map) {
    return FitnessPlan(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      sportIds: (map['sportIds'] as String).split(','),
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      targetDuration: map['targetDuration'] ?? 0,
      isCompleted: map['isCompleted'] == 1,
    );
  }
} 