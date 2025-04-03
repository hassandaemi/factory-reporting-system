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
    notifyListeners();
  }

  // Logout user
  void logoutUser() {
    currentUser = null;
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

  // Initialize database
  await DatabaseHelper().initDb();

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
