import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import '../../services/database_helper.dart';
import '../shared/report_detail_screen.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _forms = [];
  bool _isLoading = true;
  bool _isExporting = false;
  int? _selectedFormId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reports = await _databaseHelper.getAllReports();
      final forms = await _databaseHelper.getForms();

      setState(() {
        _reports = reports;
        _forms = forms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    if (_selectedFormId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a form to export')),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      // Get filtered reports based on selection
      final reports = await _databaseHelper.getFilteredReports(
        _selectedFormId!,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (reports.isEmpty) {
        setState(() {
          _isExporting = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('No reports to export for the selected criteria')),
          );
        }
        return;
      }

      // Get form fields to use as headers
      final formFields = await _databaseHelper.getFormFields(_selectedFormId!);

      // Create Excel document
      final excel = Excel.createExcel();
      final sheet = excel['Reports'];

      // Add headers
      List<String> headers = ['Report ID', 'Inspector', 'Date'];

      for (var field in formFields) {
        headers.add(field['label'] as String);
      }

      // Add header row
      for (var i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = headers[i];
      }

      // Add data rows
      for (var i = 0; i < reports.length; i++) {
        final report = reports[i];
        final reportId = report['id'] as int;
        final inspectorName = report['inspectorName'] as String;
        final createdAt = DateTime.parse(report['created_at'] as String);
        final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(createdAt);

        // Get report data
        final reportData = await _databaseHelper.getReportDataMap(reportId);

        // Add basic report info
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
            .value = reportId;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
            .value = inspectorName;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
            .value = formattedDate;

        // Add field data
        for (var j = 0; j < formFields.length; j++) {
          final fieldId = formFields[j]['id'] as int;
          final value = reportData[fieldId] ?? '';
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: j + 3, rowIndex: i + 1))
              .value = value;
        }
      }

      // Save Excel file
      final formName =
          _forms.firstWhere((form) => form['id'] == _selectedFormId)['name']
              as String;
      final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '${formName}_reports_$now.xlsx';

      final FileSaveLocation? saveLocation = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Excel files',
            extensions: ['xlsx'],
          ),
        ],
      );
      final String? filePath = saveLocation?.path;

      if (filePath != null) {
        final excelData = excel.encode();
        if (excelData != null) {
          File(filePath).writeAsBytesSync(excelData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Report exported successfully to: $filePath')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting to Excel: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _isExporting ? null : _exportToExcel,
            tooltip: 'Export to Excel',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Export Controls
                Card(
                  margin: const EdgeInsets.all(16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Options',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Select Form',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedFormId,
                          items: _forms.map<DropdownMenuItem<int>>((form) {
                            return DropdownMenuItem<int>(
                              value: form['id'] as int,
                              child: Text(form['name'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedFormId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, true),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Start Date',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    _startDate == null
                                        ? 'Not set'
                                        : DateFormat('MMM d, yyyy')
                                            .format(_startDate!),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, false),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'End Date',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    _endDate == null
                                        ? 'Not set'
                                        : DateFormat('MMM d, yyyy')
                                            .format(_endDate!),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.file_download),
                            label: const Text('EXPORT TO EXCEL'),
                            onPressed: _isExporting ? null : _exportToExcel,
                          ),
                        ),
                        if (_isExporting)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: LinearProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                ),

                // Reports List
                Expanded(
                  child: _reports.isEmpty
                      ? Center(
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
                                'No reports available',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _reports.length,
                          itemBuilder: (context, index) {
                            final report = _reports[index];
                            final DateTime createdAt =
                                DateTime.parse(report['created_at']);
                            final String formattedDate =
                                DateFormat('MMM d, yyyy - h:mm a')
                                    .format(createdAt);

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 16.0),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16.0),
                                title: Text(
                                  report['formName'] ?? 'Unnamed Form',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      'Inspector: ${report['inspectorName']}',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Submitted: $formattedDate',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReportDetailScreen(
                                        reportId: report['id'],
                                        formName: report['formName'],
                                        inspectorName: report['inspectorName'],
                                        createdAt: createdAt,
                                        allowDelete: true,
                                        onDelete: () {
                                          _loadData();
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
