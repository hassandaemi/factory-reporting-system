import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/form.dart' as form_models;
import '../../services/database_helper.dart';

class EditReportScreen extends StatefulWidget {
  final int reportId;
  final int formId;
  final String formName;

  const EditReportScreen({
    super.key,
    required this.reportId,
    required this.formId,
    required this.formName,
  });

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final Map<int, dynamic> _formData = {};
  List<form_models.FormField> _formFields = [];
  bool _isLoading = true;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadFormAndData();
  }

  Future<void> _loadFormAndData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load form fields
      final fieldMaps = await _databaseHelper.getFormFields(widget.formId);
      _formFields =
          fieldMaps.map((map) => form_models.FormField.fromMap(map)).toList();

      // Load report data
      final reportDataMap =
          await _databaseHelper.getReportDataMap(widget.reportId);

      // Set initial values
      for (var field in _formFields) {
        if (field.id != null && reportDataMap.containsKey(field.id)) {
          _formData[field.id!] = reportDataMap[field.id];
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading form data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _saveReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = Provider.of<AppState>(context, listen: false).currentUser!;

      // Ensure the user is the owner of this report
      final reportOwnerInfo =
          await _databaseHelper.getReportOwner(widget.reportId);
      if (reportOwnerInfo['inspector_user_id'] != user.id) {
        throw Exception('You can only edit your own reports.');
      }

      // Update the report
      await _databaseHelper.updateReport(
        widget.reportId,
        user.id!,
        _formData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report updated successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate refresh needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving report: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Report - ${widget.formName}'),
        actions: [
          if (!_isLoading && !_isSaving)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveReport,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isSaving
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Saving changes...'),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      ..._buildFormFields(),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveReport,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('SAVE CHANGES'),
                      ),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildFormFields() {
    final List<Widget> fields = [];

    for (final field in _formFields) {
      if (field.id == null) continue;

      // Add spacing between fields
      if (fields.isNotEmpty) {
        fields.add(const SizedBox(height: 16));
      }

      // Add field heading
      fields.add(
        Row(
          children: [
            Text(
              field.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 4),
            if (field.isRequired)
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      );

      // Add a small spacing
      fields.add(const SizedBox(height: 4));

      // Add the appropriate form field based on type
      switch (field.type) {
        case form_models.FieldType.text:
          fields.add(_buildTextField(field));
          break;
        case form_models.FieldType.dropdown:
          fields.add(_buildDropdownField(field));
          break;
        case form_models.FieldType.date:
          fields.add(_buildDateField(field));
          break;
      }
    }

    return fields;
  }

  Widget _buildTextField(form_models.FormField field) {
    final initialValue = _formData[field.id!] as String? ?? '';

    return TextFormField(
      initialValue: initialValue,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      minLines: 1,
      validator: field.isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            }
          : null,
      onChanged: (value) {
        _formData[field.id!] = value;
      },
    );
  }

  Widget _buildDropdownField(form_models.FormField field) {
    final options = field.options ?? [];
    final currentValue = _formData[field.id!] as String? ?? '';

    // Ensure the current value is in the options list
    final String? value = options.contains(currentValue) ? currentValue : null;

    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ),
      items: options
          .map((option) => DropdownMenuItem(
                value: option,
                child: Text(option),
              ))
          .toList(),
      validator: field.isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please select an option';
              }
              return null;
            }
          : null,
      onChanged: (newValue) {
        setState(() {
          _formData[field.id!] = newValue;
        });
      },
    );
  }

  Widget _buildDateField(form_models.FormField field) {
    final initialValue = _formData[field.id!] as String? ?? '';
    DateTime? selectedDate;

    if (initialValue.isNotEmpty) {
      try {
        selectedDate = DateTime.parse(initialValue);
      } catch (e) {
        // If date parsing fails, leave it as null
      }
    }

    final dateController = TextEditingController(
      text: selectedDate != null
          ? DateFormat('yyyy-MM-dd').format(selectedDate)
          : '',
    );

    return TextFormField(
      controller: dateController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true,
      validator: field.isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a date';
              }
              return null;
            }
          : null,
      onTap: () async {
        final DateTime now = DateTime.now();
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? now,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );

        if (pickedDate != null) {
          setState(() {
            dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
            _formData[field.id!] = pickedDate.toIso8601String();
          });
        }
      },
    );
  }
}
