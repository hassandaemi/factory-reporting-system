import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'services/database_helper.dart';
import 'screens/login_screen.dart';

// App state provider
class AppState extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Get database helper instance
  DatabaseHelper get databaseHelper => _databaseHelper;

  // Add more state management here as needed
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
      home: const LoginScreen(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Factory Reporting System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Welcome to Factory Reporting System',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Phase 1: Project Setup & Database Foundation',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Factory Reporting System',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Forms'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to forms screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Reports'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to reports screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Users'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to users screen
              },
            ),
          ],
        ),
      ),
    );
  }
}
