import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:factory_reporting_system/models/user.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/form.dart';
import 'package:crypto/crypto.dart';

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

  // Force database refresh by closing and reopening
  Future<Database> refreshDatabaseConnection() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _database = await initDb();
    return _database!;
  }

  // Initialize the database
  Future<Database> initDb() async {
    // Get the directory of the executable
    final String executablePath = Platform.resolvedExecutable;
    final String executableDir = dirname(executablePath);

    // Construct the database path in the executable's directory
    final path = join(executableDir, 'factory_reports.db');

    // Ensure the directory exists (optional but good practice)
    // final dbDir = Directory(dirname(path));
    // if (!await dbDir.exists()) {
    //   await dbDir.create(recursive: true);
    // }

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

  // Helper method to insert a form with its fields in a transaction
  Future<void> insertFormWithFields(
      FormModel form, List<FormField> fields) async {
    final db = await database;

    await db.transaction((txn) async {
      // Insert the form and get its ID
      final formMap = form.toMap();
      final formId = await txn.insert('Forms', formMap);

      // Insert each field with the form ID
      for (int i = 0; i < fields.length; i++) {
        final field = fields[i];
        final fieldMap = field.toMap();
        fieldMap['form_id'] = formId;
        fieldMap['field_order'] = i; // Set order based on list index

        await txn.insert('FormFields', fieldMap);
      }
    });
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

  // Helper method to save a complete report with all form data
  Future<int> saveReport(
      int formId, int inspectorId, Map<int, dynamic> formData) async {
    final db = await database;
    int reportId = 0;

    await db.transaction((txn) async {
      // Insert the report and get its ID
      reportId = await txn.insert('Reports', {
        'form_id': formId,
        'inspector_user_id': inspectorId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Insert each field's data
      for (final entry in formData.entries) {
        final fieldId = entry.key;
        final value = entry.value;

        await txn.insert('ReportData', {
          'report_id': reportId,
          'form_field_id': fieldId,
          'value': value.toString(),
        });
      }
    });

    return reportId;
  }

  // Delete a report and its data
  Future<int> deleteReport(int reportId) async {
    final db = await database;
    // Since we have ON DELETE CASCADE, we just need to delete the report
    return await db.delete(
      'Reports',
      where: 'id = ?',
      whereArgs: [reportId],
    );
  }

  // Get reports for a specific inspector
  Future<List<Map<String, dynamic>>> getReportsForInspector(
      int inspectorId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT R.id, R.form_id, R.created_at, F.name as formName
      FROM Reports R
      JOIN Forms F ON R.form_id = F.id
      WHERE R.inspector_user_id = ?
      ORDER BY R.created_at DESC
    ''', [inspectorId]);
  }

  // Get all reports (admin view)
  Future<List<Map<String, dynamic>>> getAllReports() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT R.id, R.form_id, R.created_at, F.name as formName, U.username as inspectorName
      FROM Reports R
      JOIN Forms F ON R.form_id = F.id
      JOIN Users U ON R.inspector_user_id = U.id
      ORDER BY R.created_at DESC
    ''');
  }

  // Get report details with field labels
  Future<List<Map<String, dynamic>>> getReportDataWithFieldLabels(
      int reportId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT FF.label, RD.value
      FROM ReportData RD
      JOIN FormFields FF ON RD.form_field_id = FF.id
      WHERE RD.report_id = ?
      ORDER BY FF.field_order ASC
    ''', [reportId]);
  }

  // Get filtered reports for export
  Future<List<Map<String, dynamic>>> getFilteredReports(int formId,
      {DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    String query = '''
      SELECT R.id, R.created_at, U.username as inspectorName
      FROM Reports R
      JOIN Users U ON R.inspector_user_id = U.id
      WHERE R.form_id = ?
    ''';

    List<dynamic> args = [formId];

    if (startDate != null) {
      query += ' AND R.created_at >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      // Add one day to include the full end date
      final adjustedEndDate =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query += ' AND R.created_at <= ?';
      args.add(adjustedEndDate.toIso8601String());
    }

    query += ' ORDER BY R.created_at ASC';

    return await db.rawQuery(query, args);
  }

  // Get report data map for export
  Future<Map<int, String>> getReportDataMap(int reportId) async {
    final db = await database;
    final results = await db.query(
      'ReportData',
      columns: ['form_field_id', 'value'],
      where: 'report_id = ?',
      whereArgs: [reportId],
    );

    final Map<int, String> dataMap = {};
    for (var row in results) {
      final fieldId = row['form_field_id'] as int;
      final value = row['value'] as String? ?? '';
      dataMap[fieldId] = value;
    }

    return dataMap;
  }

  // Helper method to insert a form assignment
  Future<int> insertFormAssignment(Map<String, dynamic> assignment) async {
    final db = await database;
    return await db.insert('FormAssignments', assignment);
  }

  // Get all form assignments
  Future<List<Map<String, dynamic>>> getFormAssignments() async {
    final db = await database;
    return await db.query('FormAssignments');
  }

  // Get assigned forms for a specific inspector
  Future<List<Map<String, dynamic>>> getAssignedFormsForInspector(
      int inspectorId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT F.*
      FROM Forms F
      JOIN FormAssignments FA ON F.id = FA.form_id
      WHERE FA.inspector_user_id = ?
    ''', [inspectorId]);
  }

  // Add a form assignment
  Future<int> addFormAssignment(int formId, int inspectorId) async {
    final db = await database;
    return await db.insert(
      'FormAssignments',
      {
        'form_id': formId,
        'inspector_user_id': inspectorId,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Remove a form assignment
  Future<int> removeFormAssignment(int formId, int inspectorId) async {
    final db = await database;
    return await db.delete(
      'FormAssignments',
      where: 'form_id = ? AND inspector_user_id = ?',
      whereArgs: [formId, inspectorId],
    );
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

  // Helper method to update a form with its fields in a transaction
  Future<void> updateFormWithFields(
      FormModel form, List<FormField> updatedFields) async {
    final db = await database;

    await db.transaction((txn) async {
      // Update the form
      if (form.id != null) {
        final formMap = form.toMap();
        // Remove the id from the map as we don't want to update that
        formMap.remove('id');
        // Add updated timestamp
        formMap['created_at'] = DateTime.now().toIso8601String();

        await txn.update(
          'Forms',
          formMap,
          where: 'id = ?',
          whereArgs: [form.id],
        );

        // Get current fields from DB
        final currentFieldMaps = await txn.query(
          'FormFields',
          where: 'form_id = ?',
          whereArgs: [form.id],
        );

        final currentFieldIds =
            currentFieldMaps.map<int>((map) => map['id'] as int).toSet();

        // Track new fields (no ID) or updated fields (with ID)
        final updatedFieldIds = <int>{};

        // Process each updated field
        for (int i = 0; i < updatedFields.length; i++) {
          final field = updatedFields[i];

          if (field.id != null && currentFieldIds.contains(field.id)) {
            // Update existing field
            final fieldMap = field.toMap();
            // Remove the id from the map as we don't want to update that
            fieldMap.remove('id');
            fieldMap['form_id'] = form.id;
            fieldMap['field_order'] = i;

            await txn.update(
              'FormFields',
              fieldMap,
              where: 'id = ?',
              whereArgs: [field.id],
            );

            updatedFieldIds.add(field.id!);
          } else {
            // Insert new field
            final fieldMap = field.toMap();
            fieldMap['form_id'] = form.id;
            fieldMap['field_order'] = i;

            await txn.insert('FormFields', fieldMap);
          }
        }

        // Delete fields that are no longer in the updated list
        for (final currentId in currentFieldIds) {
          if (!updatedFieldIds.contains(currentId)) {
            await txn.delete(
              'FormFields',
              where: 'id = ?',
              whereArgs: [currentId],
            );
          }
        }
      }
    });
  }

  // Delete a user by ID
  Future<int> deleteUser(int userId) async {
    final db = await database;
    return await db.delete(
      'Users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Update user password
  Future<int> updateUserPassword(int userId, String newPassword) async {
    final db = await database;

    // Hash the password using the same method as in the User model
    final bytes = utf8.encode(newPassword);
    final digest = sha256.convert(bytes);
    final hashedPassword = digest.toString();

    return await db.update(
      'Users',
      {'password_hash': hashedPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Update user credentials (username and/or password)
  Future<int> updateUserCredentials(
      int userId, String? newUsername, String? newPassword) async {
    final db = await database;

    final Map<String, dynamic> updateValues = {};

    // Update username if provided
    if (newUsername != null && newUsername.isNotEmpty) {
      updateValues['username'] = newUsername;
    }

    // Update password if provided
    if (newPassword != null && newPassword.isNotEmpty) {
      // Hash the password using the same method as in the User model
      final bytes = utf8.encode(newPassword);
      final digest = sha256.convert(bytes);
      updateValues['password_hash'] = digest.toString();
    }

    // Only proceed if there are values to update
    if (updateValues.isEmpty) {
      return 0;
    }

    return await db.update(
      'Users',
      updateValues,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Create default admin user if it doesn't exist
  Future<void> ensureDefaultAdminExists() async {
    // Check if admin user already exists
    final adminUser = await getUserByUsername('admin');

    // If admin doesn't exist, create it
    if (adminUser == null) {
      // Create default admin user with username 'admin' and password 'admin123'
      final user = User(
        username: 'admin',
        password: 'admin123',
        role: UserRole.admin,
      );

      await insertUser(user.toMap());
    }
  }

  // Delete a form by ID
  Future<int> deleteForm(int formId) async {
    final db = await database;
    return await db.delete(
      'Forms',
      where: 'id = ?',
      whereArgs: [formId],
    );
  }

  // Get the owner of a report (returns inspector_user_id)
  Future<Map<String, dynamic>> getReportOwner(int reportId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'Reports',
      columns: ['inspector_user_id'],
      where: 'id = ?',
      whereArgs: [reportId],
      limit: 1,
    );

    if (results.isEmpty) {
      throw Exception('Report not found');
    }

    return results.first;
  }

  // Update an existing report and its data
  Future<void> updateReport(
      int reportId, int inspectorId, Map<int, dynamic> formData) async {
    final db = await database;

    await db.transaction((txn) async {
      // Update the report timestamp
      await txn.update(
        'Reports',
        {
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ? AND inspector_user_id = ?',
        whereArgs: [reportId, inspectorId],
      );

      // Delete existing report data
      await txn.delete(
        'ReportData',
        where: 'report_id = ?',
        whereArgs: [reportId],
      );

      // Insert updated report data
      for (final entry in formData.entries) {
        final fieldId = entry.key;
        final value = entry.value;

        await txn.insert('ReportData', {
          'report_id': reportId,
          'form_field_id': fieldId,
          'value': value.toString(),
        });
      }
    });
  }

  // Count assigned forms for an inspector
  Future<int> countAssignedFormsForInspector(int inspectorId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM FormAssignments
      WHERE inspector_user_id = ?
    ''', [inspectorId]);

    return result.isNotEmpty ? (result.first['count'] as int) : 0;
  }

  // Count submitted reports for an inspector
  Future<int> countReportsForInspector(int inspectorId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM Reports
      WHERE inspector_user_id = ?
    ''', [inspectorId]);

    return result.isNotEmpty ? (result.first['count'] as int) : 0;
  }

  // Get inspector dashboard statistics
  Future<Map<String, int>> getInspectorStatistics(int inspectorId) async {
    final assignedFormsCount =
        await countAssignedFormsForInspector(inspectorId);
    final submittedReportsCount = await countReportsForInspector(inspectorId);

    return {
      'assignedForms': assignedFormsCount,
      'submittedReports': submittedReportsCount,
    };
  }
}
