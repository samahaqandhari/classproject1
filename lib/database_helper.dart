import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  // For the original DatabaseHelper
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'attendance.db');
      return await openDatabase(
        path,
        version: 2, // Updated version for schema changes
        onCreate: (db, version) {
          return db.execute(
            '''
            CREATE TABLE attendance (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              prayer TEXT,
              timestamp TEXT,
              date TEXT
            )
            ''',
          );
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            // Add the new 'date' column to existing database
            await db.execute('ALTER TABLE attendance ADD COLUMN date TEXT');
          }
        },
      );
    } catch (e) {
      throw Exception("Error initializing database: $e");
    }
  }

  // Insert attendance in the original helper
  Future<void> insertAttendance(String prayer, String timestamp, String date) async {
    try {
      final db = await database;
      await db.insert(
        'attendance',
        {'prayer': prayer, 'timestamp': timestamp, 'date': date},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print("Error inserting attendance: $e");
      throw Exception("Failed to insert attendance");
    }
  }

  // Get attendance from the original helper
  Future<List<Map<String, dynamic>>> getAttendance() async {
    try {
      final db = await database;
      return await db.query('attendance');
    } catch (e) {
      print("Error retrieving attendance: $e");
      throw Exception("Failed to retrieve attendance");
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceByDate(String date) async {
    try {
      final db = await database;
      return await db.query(
        'attendance',
        where: 'date = ?',
        whereArgs: [date],
      );
    } catch (e) {
      print("Error retrieving attendance by date: $e");
      throw Exception("Failed to retrieve attendance by date");
    }
  }

  Future<void> clearAttendance() async {
    try {
      final db = await database;
      await db.delete('attendance');
    } catch (e) {
      print("Error clearing attendance: $e");
      throw Exception("Failed to clear attendance");
    }
  }

  Future<void> updateAttendance(int id, String prayer, String timestamp, String date) async {
    try {
      final db = await database;
      await db.update(
        'attendance',
        {'prayer': prayer, 'timestamp': timestamp, 'date': date},
        where: 'id = ?',
        whereArgs: [id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print("Error updating attendance: $e");
      throw Exception("Failed to update attendance");
    }
  }

  // Clear all data from the database (used during logout)
  Future<void> clearDatabase() async {
    try {
      final db = await database;
      await db.delete('attendance'); // Deletes all records from the 'attendance' table
    } catch (e) {
      print("Error clearing entire database: $e");
      throw Exception("Failed to clear entire database");
    }
  }

  // ------------------ Second version of the DatabaseHelper ------------------

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database2;

  DatabaseHelper._init();

  Future<Database> get database2 async {
    if (_database2 != null) return _database2!;
    _database2 = await _initDB('attendance.db');
    return _database2!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute(''' 
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        prayer TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  // Insert attendance in second version
  Future<void> insertAttendance2(Map<String, dynamic> attendance) async {
    final db = await instance.database2;
    await db.insert('attendance', attendance);
  }

  // Get attendance by date in second version
  Future<List<Map<String, dynamic>>> getAttendanceByDate2(String date) async {
    final db = await instance.database2;
    return await db.query('attendance', where: 'date = ?', whereArgs: [date]);
  }

  // Update attendance in second version
  Future<void> updateAttendance2(String prayer, String date, String time, String userId) async {
    final db = await instance.database2;
    await db.update(
      'attendance',
      {'prayer': prayer, 'date': date, 'timestamp': time},
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );
  }

  // Clear the database (for logout) in second version
  Future<void> clearDatabase2() async {
    final db = await instance.database2;
    await db.delete('attendance');
  }
}
