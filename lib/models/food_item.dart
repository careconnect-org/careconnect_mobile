class FoodItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final int calories;
  final String imageUrl;
  final List<String> ingredients;
  final String recipeUrl;

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.calories,
    required this.imageUrl,
    required this.ingredients,
    required this.recipeUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'calories': calories,
      'imageUrl': imageUrl,
      'ingredients': ingredients.join(','),
      'recipeUrl': recipeUrl,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      calories: map['calories'],
      imageUrl: map['imageUrl'],
      ingredients: map['ingredients'].toString().split(','),
      recipeUrl: map['recipeUrl'],
    );
  }
} 