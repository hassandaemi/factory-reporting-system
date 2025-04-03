import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/form.dart' as form_models;
import 'create_edit_form_screen.dart';

class FormManagementScreen extends StatefulWidget {
  const FormManagementScreen({super.key});

  @override
  State<FormManagementScreen> createState() => _FormManagementScreenState();
}

class _FormManagementScreenState extends State<FormManagementScreen> {
  List<form_models.FormModel> _forms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchForms();
  }

  Future<void> _fetchForms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbHelper =
          Provider.of<AppState>(context, listen: false).databaseHelper;
      final formMaps = await dbHelper.getForms();

      setState(() {
        _forms =
            formMaps.map((map) => form_models.FormModel.fromMap(map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load forms: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Forms'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _forms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No forms found',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _navigateToCreateForm(context),
                        child: const Text('Create Form'),
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
                        'Forms',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _forms.length,
                          itemBuilder: (context, index) {
                            final form = _forms[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Icon(Icons.description,
                                      color: Colors.white),
                                ),
                                title: Text(
                                  form.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  form.description ?? 'No description',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.info_outline),
                                  onPressed: () {
                                    // View form details in future phase
                                  },
                                ),
                                onTap: () async {
                                  // View form details and fields
                                  final dbHelper = Provider.of<AppState>(
                                          context,
                                          listen: false)
                                      .databaseHelper;
                                  if (form.id != null) {
                                    final fieldMaps =
                                        await dbHelper.getFormFields(form.id!);
                                    final fields = fieldMaps
                                        .map((map) =>
                                            form_models.FormField.fromMap(map))
                                        .toList();

                                    _showFormDetailsDialog(form, fields);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreateForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEditFormScreen(),
      ),
    ).then((_) => _fetchForms());
  }

  void _showFormDetailsDialog(
      form_models.FormModel form, List<form_models.FormField> fields) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(form.name),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description: ${form.description ?? 'None'}'),
              const SizedBox(height: 8),
              const Text(
                'Fields:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: fields.isEmpty
                    ? const Text('No fields')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: fields.length,
                        itemBuilder: (context, index) {
                          final field = fields[index];
                          return ListTile(
                            dense: true,
                            title: Text(field.label),
                            subtitle: Text(
                              '${field.type.toString().split('.').last} · ' +
                                  (field.isRequired ? 'Required' : 'Optional'),
                            ),
                            trailing:
                                field.type == form_models.FieldType.dropdown
                                    ? Tooltip(
                                        message:
                                            'Options: ${field.options?.join(", ") ?? "None"}',
                                        child: const Icon(Icons.list),
                                      )
                                    : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
