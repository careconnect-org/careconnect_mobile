class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String imageUrl;
  final bool isFavorite;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.imageUrl,
    this.isFavorite = false,
  });

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      specialty: map['specialty'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite,
    };
  }
} 