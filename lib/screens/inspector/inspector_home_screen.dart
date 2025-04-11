import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/user.dart';
import '../../services/database_helper.dart';
import 'inspector_forms_screen.dart';
import 'inspector_reports_screen.dart';
import '../about_page.dart';

class InspectorHomeScreen extends StatefulWidget {
  const InspectorHomeScreen({super.key});

  @override
  State<InspectorHomeScreen> createState() => _InspectorHomeScreenState();
}

class _InspectorHomeScreenState extends State<InspectorHomeScreen> {
  late User user;
  late DatabaseHelper _databaseHelper;
  Map<String, int> _statistics = {'assignedForms': 0, 'submittedReports': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    user = Provider.of<AppState>(context, listen: false).currentUser!;
    _databaseHelper =
        Provider.of<AppState>(context, listen: false).databaseHelper;
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    if (user.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _databaseHelper.getInspectorStatistics(user.id!);
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading statistics: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final padding = isSmallScreen ? 16.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspector Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadStatistics,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Provider.of<AppState>(context, listen: false).logoutUser();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return RefreshIndicator(
                  onRefresh: _loadStatistics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeSection(context, user, theme),
                          SizedBox(height: padding),
                          _buildStatisticsSection(
                              context, theme, isSmallScreen),
                          SizedBox(height: padding * 2),
                          _buildDashboardGrid(context, isSmallScreen, padding),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      drawer: _buildDrawer(context, theme),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InspectorFormsScreen(user: user),
            ),
          ).then((_) => _loadStatistics());
        },
        tooltip: 'Fill Form',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatisticsSection(
      BuildContext context, ThemeData theme, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Activity',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatisticItem(
                context,
                'Assigned Forms',
                _statistics['assignedForms'].toString(),
                Icons.assignment_outlined,
                Colors.blue,
                theme,
              ),
              _buildStatisticItem(
                context,
                'Submitted Reports',
                _statistics['submittedReports'].toString(),
                Icons.fact_check_outlined,
                Colors.green,
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(
      BuildContext context, User user, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              user.username[0].toUpperCase(),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  user.username,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid(
      BuildContext context, bool isSmallScreen, double padding) {
    return GridView.count(
      crossAxisCount: isSmallScreen ? 1 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: padding,
      mainAxisSpacing: padding,
      childAspectRatio: isSmallScreen ? 1.5 : 1.2,
      children: [
        _buildDashboardItem(
          context,
          'Forms',
          Icons.assignment,
          'View and complete assigned inspection forms',
          Colors.blue,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InspectorFormsScreen(user: user),
              ),
            );
          },
        ),
        _buildDashboardItem(
          context,
          'Reports',
          Icons.assessment,
          'Access and manage your inspection reports',
          Colors.green,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InspectorReportsScreen(user: user),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDashboardItem(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(180),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, ThemeData theme) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.onPrimary,
                  child: Text(
                    user.username[0].toUpperCase(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Inspector Menu',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  Icons.dashboard,
                  'Dashboard',
                  () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  context,
                  Icons.assignment,
                  'My Assigned Forms',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InspectorFormsScreen(user: user),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  Icons.history,
                  'Completed Reports',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            InspectorReportsScreen(user: user),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  Icons.person,
                  'My Profile',
                  () {
                    Navigator.pop(context);
                    // TODO: Navigate to profile screen
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  Icons.info_outline,
                  'About App',
                  () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
