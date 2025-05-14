class SportRecommendation {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String youtubeLink;
  final String category;
  final int duration;
  final String difficulty;

  SportRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.youtubeLink,
    required this.category,
    required this.duration,
    required this.difficulty,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'youtubeLink': youtubeLink,
      'category': category,
      'duration': duration,
      'difficulty': difficulty,
    };
  }

  factory SportRecommendation.fromMap(Map<String, dynamic> map) {
    return SportRecommendation(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      youtubeLink: map['youtubeLink'] ?? '',
      category: map['category'] ?? '',
      duration: map['duration'] ?? 0,
      difficulty: map['difficulty'] ?? 'Beginner',
    );
  }
} 