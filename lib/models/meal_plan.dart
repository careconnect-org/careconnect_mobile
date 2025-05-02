class MealPlan {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> foodIds;
  final int targetCalories;
  final bool isCompleted;

  MealPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.foodIds,
    required this.targetCalories,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'foodIds': foodIds.join(','),
      'targetCalories': targetCalories,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory MealPlan.fromMap(Map<String, dynamic> map) {
    return MealPlan(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      foodIds: map['foodIds'].toString().split(','),
      targetCalories: map['targetCalories'],
      isCompleted: map['isCompleted'] == 1,
    );
  }
} 