class ReportData {
  final int? id;
  final int? reportId;
  final int formFieldId;
  final String? value;

  ReportData({
    this.id,
    this.reportId,
    required this.formFieldId,
    this.value,
  });

  // Convert ReportData to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'report_id': reportId,
      'form_field_id': formFieldId,
      'value': value,
    };
  }

  // Create ReportData from Map
  factory ReportData.fromMap(Map<String, dynamic> map) {
    return ReportData(
      id: map['id'],
      reportId: map['report_id'],
      formFieldId: map['form_field_id'],
      value: map['value'],
    );
  }
}

class Report {
  final int? id;
  final int formId;
  final int inspectorUserId;
  final String? createdAt;
  final String? updatedAt;
  final List<ReportData> data;

  Report({
    this.id,
    required this.formId,
    required this.inspectorUserId,
    this.createdAt,
    this.updatedAt,
    this.data = const [],
  });

  // Convert Report to Map (without data)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'form_id': formId,
      'inspector_user_id': inspectorUserId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Create Report from Map (without data)
  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'],
      formId: map['form_id'],
      inspectorUserId: map['inspector_user_id'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  // Create a copy of this report with data
  Report copyWith({List<ReportData>? data}) {
    return Report(
      id: id,
      formId: formId,
      inspectorUserId: inspectorUserId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      data: data ?? this.data,
    );
  }
}
