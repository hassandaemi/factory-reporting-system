import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Factory constructor
  factory DatabaseHelper() => _instance;

  // Private constructor
  DatabaseHelper._internal();

  // Database getter
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDb();
    return _database!;
  }

  // Initialize the database
  Future<Database> initDb() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'factory_reports.db');

    return await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
      ),
    );
  }

  // Create the database tables
  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE Users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL CHECK(role IN ('admin', 'inspector'))
      )
    ''');

    // Forms table
    await db.execute('''
      CREATE TABLE Forms(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // FormFields table
    await db.execute('''
      CREATE TABLE FormFields(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        form_id INTEGER NOT NULL,
        label TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('text', 'dropdown', 'date')),
        is_required INTEGER NOT NULL DEFAULT 0,
        options TEXT,
        field_order INTEGER DEFAULT 0,
        FOREIGN KEY(form_id) REFERENCES Forms(id) ON DELETE CASCADE
      )
    ''');

    // Reports table
    await db.execute('''
      CREATE TABLE Reports(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        form_id INTEGER NOT NULL,
        inspector_user_id INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(form_id) REFERENCES Forms(id),
        FOREIGN KEY(inspector_user_id) REFERENCES Users(id)
      )
    ''');

    // ReportData table
    await db.execute('''
      CREATE TABLE ReportData(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        report_id INTEGER NOT NULL,
        form_field_id INTEGER NOT NULL,
        value TEXT,
        FOREIGN KEY(report_id) REFERENCES Reports(id) ON DELETE CASCADE,
        FOREIGN KEY(form_field_id) REFERENCES FormFields(id)
      )
    ''');

    // FormAssignments table
    await db.execute('''
      CREATE TABLE FormAssignments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        form_id INTEGER NOT NULL,
        inspector_user_id INTEGER NOT NULL,
        FOREIGN KEY(form_id) REFERENCES Forms(id) ON DELETE CASCADE,
        FOREIGN KEY(inspector_user_id) REFERENCES Users(id) ON DELETE CASCADE,
        UNIQUE(form_id, inspector_user_id)
      )
    ''');
  }

  // Helper method to insert a user
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('Users', user);
  }

  // Helper method to insert a form
  Future<int> insertForm(Map<String, dynamic> form) async {
    final db = await database;
    return await db.insert('Forms', form);
  }

  // Helper method to insert a form field
  Future<int> insertFormField(Map<String, dynamic> formField) async {
    final db = await database;
    return await db.insert('FormFields', formField);
  }

  // Helper method to insert a report
  Future<int> insertReport(Map<String, dynamic> report) async {
    final db = await database;
    return await db.insert('Reports', report);
  }

  // Helper method to insert report data
  Future<int> insertReportData(Map<String, dynamic> reportData) async {
    final db = await database;
    return await db.insert('ReportData', reportData);
  }

  // Helper method to insert a form assignment
  Future<int> insertFormAssignment(Map<String, dynamic> assignment) async {
    final db = await database;
    return await db.insert('FormAssignments', assignment);
  }

  // Get user by username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'Users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  // Get all inspectors
  Future<List<Map<String, dynamic>>> getInspectors() async {
    final db = await database;
    return await db.query(
      'Users',
      where: 'role = ?',
      whereArgs: ['inspector'],
    );
  }

  // Get all users
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('Users');
  }

  // Get all forms
  Future<List<Map<String, dynamic>>> getForms() async {
    final db = await database;
    return await db.query('Forms');
  }

  // Get form fields for a form
  Future<List<Map<String, dynamic>>> getFormFields(int formId) async {
    final db = await database;
    return await db.query('FormFields',
        where: 'form_id = ?', whereArgs: [formId], orderBy: 'field_order ASC');
  }

  // Get reports for a user
  Future<List<Map<String, dynamic>>> getReports(int userId) async {
    final db = await database;
    return await db
        .query('Reports', where: 'inspector_user_id = ?', whereArgs: [userId]);
  }

  // Get report data for a report
  Future<List<Map<String, dynamic>>> getReportData(int reportId) async {
    final db = await database;
    return await db
        .query('ReportData', where: 'report_id = ?', whereArgs: [reportId]);
  }
}
