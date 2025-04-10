import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'services/database_helper.dart';
import 'screens/login_screen.dart';
import 'models/user.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/inspector/inspector_home_screen.dart';

// App state provider
class AppState extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  User? currentUser;

  // Get database helper instance
  DatabaseHelper get databaseHelper => _databaseHelper;

  // Login user
  void loginUser(User user) {
    currentUser = user;

    // Force Flutter to rebuild with the new user state
    // Adding a slight delay ensures the UI has time to process the state change
    Future.delayed(Duration.zero, () {
      notifyListeners();
    });
  }

  // Logout user
  void logoutUser() {
    currentUser = null;
    // Refresh database connection on logout to ensure fresh state on next login
    _databaseHelper.refreshDatabaseConnection().then((_) {});
    notifyListeners();
  }
}

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Initialize FFI loader
    sqfliteFfiInit();
    // Set database factory to FFI
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize database and ensure a fresh connection
  final dbHelper = DatabaseHelper();
  await dbHelper.initDb();
  await dbHelper.refreshDatabaseConnection();
  
  // Ensure default admin user exists
  await dbHelper.ensureDefaultAdminExists();

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Factory Reporting System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Consumer<AppState>(
        builder: (context, appState, _) {
          if (appState.currentUser == null) {
            return const LoginScreen();
          } else if (appState.currentUser!.role == UserRole.admin) {
            return const AdminHomeScreen();
          } else {
            return const InspectorHomeScreen();
          }
        },
      ),
    );
  }
}
