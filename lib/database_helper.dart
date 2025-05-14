import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/sport_recommendation.dart';
import 'models/fitness_plan.dart';
import 'models/food_item.dart';
import 'models/meal_plan.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sports.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sports (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        youtubeLink TEXT NOT NULL,
        category TEXT NOT NULL,
        duration INTEGER NOT NULL,
        difficulty TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE fitness_plans (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        sportIds TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        targetDuration INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE foods(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        calories INTEGER,
        imageUrl TEXT,
        ingredients TEXT,
        recipeUrl TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_plans(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        foodIds TEXT,
        targetCalories INTEGER,
        isCompleted INTEGER DEFAULT 0
      )
    ''');
  }

  Future<int> createSport(SportRecommendation sport) async {
    final db = await instance.database;
    return await db.insert('sports', sport.toMap());
  }

  Future<List<SportRecommendation>> getAllSports() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('sports');
    return List.generate(maps.length, (i) => SportRecommendation.fromMap(maps[i]));
  }

  Future<SportRecommendation?> getSport(String id) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sports',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return SportRecommendation.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSport(SportRecommendation sport) async {
    final db = await instance.database;
    return await db.update(
      'sports',
      sport.toMap(),
      where: 'id = ?',
      whereArgs: [sport.id],
    );
  }

  Future<int> deleteSport(String id) async {
    final db = await instance.database;
    return await db.delete(
      'sports',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> createPlan(FitnessPlan plan) async {
    final db = await database;
    await db.insert('fitness_plans', plan.toMap());
  }

  Future<List<FitnessPlan>> getAllPlans() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('fitness_plans');
    return List.generate(maps.length, (i) => FitnessPlan.fromMap(maps[i]));
  }

  Future<void> updatePlan(FitnessPlan plan) async {
    final db = await database;
    await db.update(
      'fitness_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<void> deletePlan(String id) async {
    final db = await database;
    await db.delete(
      'fitness_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> createFood(FoodItem food) async {
    final db = await database;
    await db.insert('foods', food.toMap());
  }

  Future<List<FoodItem>> getAllFoods() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('foods');
    return List.generate(maps.length, (i) => FoodItem.fromMap(maps[i]));
  }

  Future<void> updateFood(FoodItem food) async {
    final db = await database;
    await db.update(
      'foods',
      food.toMap(),
      where: 'id = ?',
      whereArgs: [food.id],
    );
  }

  Future<void> deleteFood(String id) async {
    final db = await database;
    await db.delete(
      'foods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> createMealPlan(MealPlan plan) async {
    final db = await database;
    await db.insert('meal_plans', plan.toMap());
  }

  Future<List<MealPlan>> getAllMealPlans() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('meal_plans');
    return List.generate(maps.length, (i) => MealPlan.fromMap(maps[i]));
  }

  Future<void> updateMealPlan(MealPlan plan) async {
    final db = await database;
    await db.update(
      'meal_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<void> deleteMealPlan(String id) async {
    final db = await database;
    await db.delete(
      'meal_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
} 