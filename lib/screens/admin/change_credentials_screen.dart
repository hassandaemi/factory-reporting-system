import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/user.dart';

class ChangeCredentialsScreen extends StatefulWidget {
  const ChangeCredentialsScreen({super.key});

  @override
  State<ChangeCredentialsScreen> createState() => _ChangeCredentialsScreenState();
}

class _ChangeCredentialsScreenState extends State<ChangeCredentialsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newUsernameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the username field with the current username
    final currentUser = Provider.of<AppState>(context, listen: false).currentUser;
    if (currentUser != null) {
      _newUsernameController.text = currentUser.username;
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newUsernameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateCredentials() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final appState = Provider.of<AppState>(context, listen: false);
        final currentUser = appState.currentUser;
        final dbHelper = appState.databaseHelper;

        if (currentUser == null) {
          _showErrorSnackBar('User session expired. Please login again.');
          return;
        }

        // Verify current password
        if (!currentUser.verifyPassword(_currentPasswordController.text)) {
          _showErrorSnackBar('Current password is incorrect');
          return;
        }

        // Check if new password fields match
        final newPassword = _newPasswordController.text;
        final confirmPassword = _confirmPasswordController.text;
        
        if (newPassword.isNotEmpty && newPassword != confirmPassword) {
          _showErrorSnackBar('New passwords do not match');
          return;
        }

        // Update credentials
        final newUsername = _newUsernameController.text != currentUser.username 
            ? _newUsernameController.text 
            : null;
            
        final passwordToUpdate = newPassword.isNotEmpty ? newPassword : null;

        // Only proceed if there are changes
        if (newUsername == null && passwordToUpdate == null) {
          _showErrorSnackBar('No changes were made');
          return;
        }

        // Update user credentials in database
        final result = await dbHelper.updateUserCredentials(
          currentUser.id!,
          newUsername,
          passwordToUpdate,
        );

        if (result > 0) {
          // Create updated user object
          User updatedUser;
          
          if (passwordToUpdate != null) {
            // If password was changed, create new User with the new password
            updatedUser = User(
              id: currentUser.id,
              username: newUsername ?? currentUser.username,
              password: passwordToUpdate,
              role: currentUser.role,
            );
          } else {
            // If only username was changed, create User with existing password hash
            updatedUser = User.withHash(
              id: currentUser.id,
              username: newUsername ?? currentUser.username,
              passwordHash: currentUser.passwordHash,
              role: currentUser.role,
            );
          }
          
          // Update the user in AppState
          appState.loginUser(updatedUser);
          
          if (!mounted) return;
          _showSuccessSnackBar('Credentials updated successfully');
          
          // Clear password fields
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        } else {
          _showErrorSnackBar('Failed to update credentials');
        }
      } catch (e) {
        _showErrorSnackBar('Error: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Admin Credentials'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Update Your Admin Credentials',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newUsernameController,
                  decoration: const InputDecoration(
                    labelText: 'New Username',
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
                  controller: _newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password (leave blank to keep current)',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (_newPasswordController.text.isNotEmpty && 
                        (value == null || value.isEmpty)) {
                      return 'Please confirm your new password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateCredentials,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Update Credentials'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}