import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('health_recommendations.db');
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
      CREATE TABLE health_recommendations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        created_at TEXT NOT NULL,
        patient_id TEXT,
        is_read INTEGER DEFAULT 0
      )
    ''');
  }

  Future<int> insertRecommendation(Map<String, dynamic> recommendation) async {
    final db = await database;
    return await db.insert('health_recommendations', recommendation);
  }

  Future<List<Map<String, dynamic>>> getRecommendations(String? patientId) async {
    final db = await database;
    if (patientId != null) {
      return await db.query(
        'health_recommendations',
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'created_at DESC',
      );
    } else {
      return await db.query(
        'health_recommendations',
        orderBy: 'created_at DESC',
      );
    }
  }

  Future<int> markAsRead(int id) async {
    final db = await database;
    return await db.update(
      'health_recommendations',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteRecommendation(int id) async {
    final db = await database;
    return await db.delete(
      'health_recommendations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> createPatientsTable() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS patients(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getPatients() async {
    final db = await database;
    return await db.query('patients');
  }

  Future<void> insertPatient(Map<String, dynamic> patient) async {
    final db = await database;
    await db.insert('patients', patient);
  }

  Future<int> updateRecommendation(Map<String, dynamic> recommendation) async {
    final db = await database;
    return await db.update(
      'health_recommendations',
      recommendation,
      where: 'id = ?',
      whereArgs: [recommendation['id']],
    );
  }
} 