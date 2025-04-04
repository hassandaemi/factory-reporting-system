import 'package:flutter/material.dart';
import '../../models/form.dart';
import '../../models/user.dart';
import '../../services/database_helper.dart';
import 'fill_form_screen.dart';

class InspectorFormsScreen extends StatefulWidget {
  final User user;

  const InspectorFormsScreen({
    super.key,
    required this.user,
  });

  @override
  State<InspectorFormsScreen> createState() => _InspectorFormsScreenState();
}

class _InspectorFormsScreenState extends State<InspectorFormsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<FormModel> _assignedForms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignedForms();
  }

  Future<void> _loadAssignedForms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure we have a valid inspector ID
      if (widget.user.id == null) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid user ID')),
          );
        }
        return;
      }

      final forms =
          await _databaseHelper.getAssignedFormsForInspector(widget.user.id!);
      setState(() {
        _assignedForms = forms.map((form) => FormModel.fromMap(form)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading forms: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Forms'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignedForms.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No forms assigned yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Forms will appear here once they are assigned to you',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _assignedForms.length,
                  itemBuilder: (context, index) {
                    final form = _assignedForms[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[700],
                          child: const Icon(
                            Icons.assignment,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          form.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: form.description != null &&
                                form.description!.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(form.description!),
                              )
                            : null,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          if (form.id != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FillFormScreen(
                                  formId: form.id!,
                                  formName: form.name,
                                ),
                              ),
                            ).then((_) => _loadAssignedForms());
                          }
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAssignedForms,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
