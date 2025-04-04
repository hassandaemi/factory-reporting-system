import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/user.dart';

class InspectorManagementScreen extends StatefulWidget {
  const InspectorManagementScreen({super.key});

  @override
  State<InspectorManagementScreen> createState() =>
      _InspectorManagementScreenState();
}

class _InspectorManagementScreenState extends State<InspectorManagementScreen> {
  List<User> _inspectors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInspectors();
  }

  Future<void> _fetchInspectors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbHelper =
          Provider.of<AppState>(context, listen: false).databaseHelper;
      final inspectorMaps = await dbHelper.getInspectors();

      setState(() {
        _inspectors = inspectorMaps.map((map) => User.fromMap(map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load inspectors: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddInspectorDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Inspector'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final dbHelper = Provider.of<AppState>(context, listen: false)
                    .databaseHelper;

                // Check if username already exists
                final existingUser =
                    await dbHelper.getUserByUsername(usernameController.text);
                if (!mounted) return;

                // Check if dialog context is still valid
                if (!dialogContext.mounted) return;

                if (existingUser != null) {
                  Navigator.of(dialogContext).pop();
                  _showErrorSnackBar('Username already exists');
                  return;
                }

                // Create new inspector user
                final newInspector = User(
                  username: usernameController.text,
                  password: passwordController.text,
                  role: UserRole.inspector,
                );

                // Insert into database
                await dbHelper.insertUser(newInspector.toMap());
                if (!mounted) return;

                // Check if dialog context is still valid
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();

                // Refresh the list
                await _fetchInspectors();
                if (!mounted) return;

                _showSuccessSnackBar('Inspector added successfully');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Show confirmation dialog before deleting an inspector
  void _showDeleteConfirmationDialog(User inspector) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Inspector'),
        content: Text(
          'Are you sure you want to delete ${inspector.username}?\n\n'
          'This will also delete all their form assignments. Reports created by this inspector will remain in the system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              final dbHelper =
                  Provider.of<AppState>(context, listen: false).databaseHelper;

              // Delete the inspector
              await dbHelper.deleteUser(inspector.id!);
              if (!mounted) return;

              // Close the dialog
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }

              // Refresh the inspector list
              await _fetchInspectors();
              if (!mounted) return;

              _showSuccessSnackBar('Inspector deleted successfully');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Show dialog to edit an inspector's password
  void _showEditPasswordDialog(User inspector) {
    final formKey = GlobalKey<FormState>();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update Password for ${inspector.username}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final dbHelper = Provider.of<AppState>(context, listen: false)
                    .databaseHelper;

                // Update the password
                await dbHelper.updateUserPassword(
                  inspector.id!,
                  newPasswordController.text,
                );
                if (!mounted) return;

                // Close the dialog
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }

                _showSuccessSnackBar('Password updated successfully');
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Inspectors'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _inspectors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No inspectors found',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showAddInspectorDialog(context),
                        child: const Text('Add Inspector'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inspectors',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _inspectors.length,
                          itemBuilder: (context, index) {
                            final inspector = _inspectors[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    inspector.username
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  inspector.username,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('Inspector ID: ${inspector.id}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      tooltip: 'Edit Password',
                                      onPressed: () =>
                                          _showEditPasswordDialog(inspector),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      tooltip: 'Delete Inspector',
                                      onPressed: () =>
                                          _showDeleteConfirmationDialog(
                                              inspector),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddInspectorDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
