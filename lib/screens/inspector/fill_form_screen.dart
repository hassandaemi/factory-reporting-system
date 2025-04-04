import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../models/form.dart' as form_models;

class FillFormScreen extends StatefulWidget {
  final int formId;
  final String formName;

  const FillFormScreen({
    super.key,
    required this.formId,
    required this.formName,
  });

  @override
  State<FillFormScreen> createState() => _FillFormScreenState();
}

class _FillFormScreenState extends State<FillFormScreen> {
  List<form_models.FormField> _fields = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<int, dynamic> _formData =
      {}; // Stores entered data {fieldId: value}
  Map<int, TextEditingController> _textControllers = {}; // For text/date fields

  @override
  void initState() {
    super.initState();
    _fetchFields();
  }

  Future<void> _fetchFields() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbHelper =
          Provider.of<AppState>(context, listen: false).databaseHelper;
      final fieldMaps = await dbHelper.getFormFields(widget.formId);

      // Convert to FormField objects
      final fields =
          fieldMaps.map((map) => form_models.FormField.fromMap(map)).toList();

      // Initialize text controllers for text and date fields
      final Map<int, TextEditingController> controllers = {};
      for (var field in fields) {
        if (field.id != null &&
            (field.type == form_models.FieldType.text ||
                field.type == form_models.FieldType.date)) {
          controllers[field.id!] = TextEditingController();
        }
      }

      setState(() {
        _fields = fields;
        _textControllers = controllers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load form fields: $e');
    }
  }

  @override
  void dispose() {
    // Dispose all text controllers
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Check if there's any data to submit
      if (_formData.isEmpty) {
        _showErrorSnackBar('Please fill out at least one field');
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final inspectorId =
            Provider.of<AppState>(context, listen: false).currentUser!.id;

        if (inspectorId == null) {
          throw Exception('User ID is null');
        }

        // Get DatabaseHelper instance from AppState
        final databaseHelper =
            Provider.of<AppState>(context, listen: false).databaseHelper;

        // Save the report to the database
        await databaseHelper.saveReport(widget.formId, inspectorId, _formData);

        setState(() {
          _isSubmitting = false;
        });

        _showSuccessSnackBar('Report submitted successfully');

        // Give time for the snackbar to show before popping
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });
        _showErrorSnackBar('Error submitting report: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.formName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Fill out the form',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _fields.isEmpty
                          ? const Center(
                              child: Text(
                                'This form has no fields',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _fields.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final field = _fields[index];

                                if (field.id == null) {
                                  return const SizedBox.shrink();
                                }

                                final fieldId = field.id!;

                                // Build widget based on field type
                                switch (field.type) {
                                  case form_models.FieldType.text:
                                    return _buildTextField(field, fieldId);

                                  case form_models.FieldType.date:
                                    return _buildDateField(field, fieldId);

                                  case form_models.FieldType.dropdown:
                                    return _buildDropdownField(field, fieldId);
                                }
                              },
                            ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text('Submitting...'),
                              ],
                            )
                          : const Text('Submit Report'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(form_models.FormField field, int fieldId) {
    return TextFormField(
      controller: _textControllers[fieldId],
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.isRequired ? 'Required' : 'Optional',
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (field.isRequired && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
      onSaved: (value) {
        if (value != null && value.isNotEmpty) {
          _formData[fieldId] = value;
        }
      },
    );
  }

  Widget _buildDateField(form_models.FormField field, int fieldId) {
    return TextFormField(
      controller: _textControllers[fieldId],
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.isRequired ? 'Required' : 'Optional',
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      validator: (value) {
        if (field.isRequired && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );

        if (picked != null) {
          final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
          setState(() {
            _textControllers[fieldId]?.text = formattedDate;
            _formData[fieldId] = formattedDate;
          });
        }
      },
      onSaved: (value) {
        if (value != null && value.isNotEmpty) {
          _formData[fieldId] = value;
        }
      },
    );
  }

  Widget _buildDropdownField(form_models.FormField field, int fieldId) {
    // Parse options
    final List<String> options = field.options ?? [];

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.isRequired ? 'Required' : 'Optional',
        border: const OutlineInputBorder(),
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      value: _formData[fieldId] as String?,
      validator: (value) {
        if (field.isRequired && value == null) {
          return 'This field is required';
        }
        return null;
      },
      onChanged: (value) {
        setState(() {
          if (value != null) {
            _formData[fieldId] = value;
          }
        });
      },
      onSaved: (value) {
        if (value != null) {
          _formData[fieldId] = value;
        }
      },
    );
  }
}
