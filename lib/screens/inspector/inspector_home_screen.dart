import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'inspector_forms_screen.dart';
import 'inspector_reports_screen.dart';

class InspectorHomeScreen extends StatelessWidget {
  const InspectorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppState>(context).currentUser!;
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.04; // 4% of screen width

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspector Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AppState>(context, listen: false).logoutUser();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${user.username}!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: screenSize.width * 0.05,
                    ),
              ),
              SizedBox(height: screenSize.height * 0.03),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = screenSize.width < 600 ? 1 : 2;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: padding,
                    mainAxisSpacing: padding,
                    children: [
                      _buildDashboardItem(
                        context,
                        'Forms',
                        Icons.assignment,
                        Colors.blue,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  InspectorFormsScreen(user: user),
                            ),
                          );
                        },
                      ),
                      _buildDashboardItem(
                        context,
                        'Reports',
                        Icons.assessment,
                        Colors.green,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  InspectorReportsScreen(user: user),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
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
                'Inspector Menu',
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
              leading: const Icon(Icons.list),
              title: const Text('My Assigned Forms'),
              onTap: () {
                Navigator.pop(context);
                // Already on this screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Completed Reports'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to completed reports screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile screen
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    final screenSize = MediaQuery.of(context).size;

    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: screenSize.width * 0.1,
              color: color,
            ),
            SizedBox(height: screenSize.height * 0.02),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: screenSize.width * 0.04,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
