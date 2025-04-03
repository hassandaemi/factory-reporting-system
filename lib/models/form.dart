import 'dart:convert';

enum FieldType {
  text,
  dropdown,
  date,
}

class FormField {
  final int? id;
  final int? formId;
  final String label;
  final FieldType type;
  final bool isRequired;
  final List<String>? options;
  final int fieldOrder;

  FormField({
    this.id,
    this.formId,
    required this.label,
    required this.type,
    this.isRequired = false,
    this.options,
    this.fieldOrder = 0,
  });

  // Convert FormField to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'form_id': formId,
      'label': label,
      'type': type.toString().split('.').last,
      'is_required': isRequired ? 1 : 0,
      'options': options != null ? jsonEncode(options) : null,
      'field_order': fieldOrder,
    };
  }

  // Create FormField from Map
  factory FormField.fromMap(Map<String, dynamic> map) {
    return FormField(
      id: map['id'],
      formId: map['form_id'],
      label: map['label'],
      type: _getFieldType(map['type']),
      isRequired: map['is_required'] == 1,
      options: map['options'] != null
          ? List<String>.from(jsonDecode(map['options']))
          : null,
      fieldOrder: map['field_order'] ?? 0,
    );
  }

  static FieldType _getFieldType(String type) {
    switch (type) {
      case 'text':
        return FieldType.text;
      case 'dropdown':
        return FieldType.dropdown;
      case 'date':
        return FieldType.date;
      default:
        return FieldType.text;
    }
  }
}

class FormModel {
  final int? id;
  final String name;
  final String? description;
  final String? createdAt;
  final List<FormField> fields;

  FormModel({
    this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.fields = const [],
  });

  // Convert Form to Map (without fields)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt,
    };
  }

  // Create Form from Map (without fields)
  factory FormModel.fromMap(Map<String, dynamic> map) {
    return FormModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      createdAt: map['created_at'],
    );
  }

  // Create a copy of this form with fields
  FormModel copyWith({List<FormField>? fields}) {
    return FormModel(
      id: id,
      name: name,
      description: description,
      createdAt: createdAt,
      fields: fields ?? this.fields,
    );
  }
}
