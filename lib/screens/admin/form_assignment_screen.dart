import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/form.dart' as form_models;
import '../../models/user.dart';

class FormAssignmentScreen extends StatefulWidget {
  const FormAssignmentScreen({super.key});

  @override
  State<FormAssignmentScreen> createState() => _FormAssignmentScreenState();
}

class _FormAssignmentScreenState extends State<FormAssignmentScreen> {
  List<form_models.FormModel> _forms = [];
  List<User> _inspectors = [];
  form_models.FormModel? _selectedForm;
  Map<int, Set<int>> _assignments = {}; // Map<formId, Set<inspectorId>>
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbHelper =
          Provider.of<AppState>(context, listen: false).databaseHelper;

      // Fetch forms
      final formMaps = await dbHelper.getForms();
      final forms =
          formMaps.map((map) => form_models.FormModel.fromMap(map)).toList();

      // Fetch inspectors
      final inspectorMaps = await dbHelper.getInspectors();
      final inspectors = inspectorMaps.map((map) => User.fromMap(map)).toList();

      // Fetch existing assignments
      final assignmentMaps = await dbHelper.getFormAssignments();

      // Process assignments into a map structure
      final Map<int, Set<int>> assignments = {};
      for (final assignment in assignmentMaps) {
        final formId = assignment['form_id'] as int;
        final inspectorId = assignment['inspector_user_id'] as int;

        // Add to map
        if (!assignments.containsKey(formId)) {
          assignments[formId] = <int>{};
        }
        assignments[formId]!.add(inspectorId);
      }

      setState(() {
        _forms = forms;
        _inspectors = inspectors;
        _assignments = assignments;
        _selectedForm = forms.isNotEmpty ? forms[0] : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load data: $e');
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

  Future<void> _toggleAssignment(User inspector, bool isAssigned) async {
    if (_selectedForm == null ||
        _selectedForm!.id == null ||
        inspector.id == null) {
      return;
    }

    final formId = _selectedForm!.id!;
    final inspectorId = inspector.id!;

    try {
      final dbHelper =
          Provider.of<AppState>(context, listen: false).databaseHelper;

      if (isAssigned) {
        // Add assignment
        await dbHelper.addFormAssignment(formId, inspectorId);

        // Update local state
        setState(() {
          _assignments.putIfAbsent(formId, () => <int>{}).add(inspectorId);
        });

        _showSuccessSnackBar(
            'Form assigned to inspector ${inspector.username}');
      } else {
        // Remove assignment
        await dbHelper.removeFormAssignment(formId, inspectorId);

        // Update local state
        setState(() {
          _assignments[formId]?.remove(inspectorId);
        });

        _showSuccessSnackBar(
            'Form unassigned from inspector ${inspector.username}');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating assignment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Forms to Inspectors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _forms.isEmpty || _inspectors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _forms.isEmpty
                            ? 'No forms available. Please create forms first.'
                            : 'No inspectors available. Please add inspectors first.',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
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
                        'Select a Form:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<form_models.FormModel>(
                        value: _selectedForm,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        items: _forms.map((form) {
                          return DropdownMenuItem<form_models.FormModel>(
                            value: form,
                            child: Text(form.name),
                          );
                        }).toList(),
                        onChanged: (form) {
                          setState(() {
                            _selectedForm = form;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      if (_selectedForm != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Inspectors:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Form: ${_selectedForm!.name}',
                              style:
                                  const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _inspectors.length,
                            itemBuilder: (context, index) {
                              final inspector = _inspectors[index];
                              final isAssigned = _selectedForm?.id != null &&
                                  inspector.id != null &&
                                  (_assignments[_selectedForm!.id!]
                                          ?.contains(inspector.id!) ??
                                      false);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: CheckboxListTile(
                                  title: Text(inspector.username),
                                  subtitle:
                                      Text('Inspector ID: ${inspector.id}'),
                                  value: isAssigned,
                                  onChanged: (value) {
                                    if (value != null) {
                                      _toggleAssignment(inspector, value);
                                    }
                                  },
                                  secondary: CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: Text(
                                      inspector.username
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
