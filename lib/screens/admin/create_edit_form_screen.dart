import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/form.dart' as form_models;

class CreateEditFormScreen extends StatefulWidget {
  final form_models.FormModel? editForm;
  final List<form_models.FormField>? initialFields;

  const CreateEditFormScreen({
    super.key,
    this.editForm,
    this.initialFields,
  });

  @override
  State<CreateEditFormScreen> createState() => _CreateEditFormScreenState();
}

class _CreateEditFormScreenState extends State<CreateEditFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<form_models.FormField> _fields = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // If editing an existing form, populate the fields
    if (widget.editForm != null) {
      _nameController.text = widget.editForm!.name;
      _descriptionController.text = widget.editForm!.description ?? '';

      if (widget.initialFields != null) {
        _fields = List.from(widget.initialFields!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      if (_fields.isEmpty) {
        _showErrorSnackBar('Please add at least one field to the form');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final form = form_models.FormModel(
          id: widget.editForm?.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        );

        final dbHelper =
            Provider.of<AppState>(context, listen: false).databaseHelper;

        // Save the form with its fields
        await dbHelper.insertFormWithFields(form, _fields);

        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;
        _showSuccessSnackBar('Form saved successfully');
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error saving form: $e');
      }
    }
  }

  void _showAddFieldDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final labelController = TextEditingController();
    form_models.FieldType selectedType = form_models.FieldType.text;
    bool isRequired = false;
    final optionsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Add Field'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Field Label',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a label';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<form_models.FieldType>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Field Type',
                        border: OutlineInputBorder(),
                      ),
                      items: form_models.FieldType.values.map((type) {
                        return DropdownMenuItem<form_models.FieldType>(
                          value: type,
                          child: Text(type.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Required'),
                      value: isRequired,
                      onChanged: (value) {
                        setStateDialog(() {
                          isRequired = value;
                        });
                      },
                    ),
                    if (selectedType == form_models.FieldType.dropdown) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: optionsController,
                        decoration: const InputDecoration(
                          labelText: 'Options (comma-separated)',
                          border: OutlineInputBorder(),
                          hintText: 'Option 1, Option 2, Option 3',
                        ),
                        validator: (value) {
                          if (selectedType == form_models.FieldType.dropdown) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter options for dropdown';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    // Parse options if dropdown type
                    List<String>? options;
                    if (selectedType == form_models.FieldType.dropdown) {
                      options = optionsController.text
                          .split(',')
                          .map((option) => option.trim())
                          .where((option) => option.isNotEmpty)
                          .toList();
                    }

                    // Create field
                    final newField = form_models.FormField(
                      label: labelController.text.trim(),
                      type: selectedType,
                      isRequired: isRequired,
                      options: options,
                    );

                    Navigator.of(context).pop();

                    // Add to fields list
                    setState(() {
                      _fields.add(newField);
                    });
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editForm == null ? 'Create New Form' : 'Edit Form'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveForm,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Form name and description
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Form Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a form name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Form Description (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Form Fields',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Field'),
                          onPressed: () => _showAddFieldDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),

                    // Fields list
                    _fields.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.0),
                            child: Center(
                              child: Text(
                                'No fields added yet. Add fields using the button above.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _fields.length,
                            itemBuilder: (context, index) {
                              final field = _fields[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: ListTile(
                                  title: Text(field.label),
                                  subtitle: Text(
                                    '${field.type.toString().split('.').last} · ${field.isRequired ? 'Required' : 'Optional'}${field.options != null ? ' · Options: ${field.options!.join(', ')}' : ''}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      setState(() {
                                        _fields.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Save Form'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
