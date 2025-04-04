import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_helper.dart';

class ReportDetailScreen extends StatefulWidget {
  final int reportId;
  final String formName;
  final String inspectorName;
  final DateTime createdAt;
  final bool allowDelete;
  final VoidCallback? onDelete;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
    required this.formName,
    required this.inspectorName,
    required this.createdAt,
    this.allowDelete = false,
    this.onDelete,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _reportData = [];
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadReportDetails();
  }

  Future<void> _loadReportDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reportData =
          await _databaseHelper.getReportDataWithFieldLabels(widget.reportId);
      setState(() {
        _reportData = reportData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading report details: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
            'Are you sure you want to delete this report? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteReport();
    }
  }

  Future<void> _deleteReport() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await _databaseHelper.deleteReport(widget.reportId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted successfully')),
        );
      }
      if (widget.onDelete != null) {
        widget.onDelete!();
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting report: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('MMMM d, yyyy - h:mm a').format(widget.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          if (widget.allowDelete)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isDeleting ? null : _confirmDelete,
              tooltip: 'Delete Report',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isDeleting
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Deleting report...'),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.formName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Inspector: ${widget.inspectorName}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Date: $formattedDate',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Report Data',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _reportData.isEmpty
                          ? const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child:
                                    Text('No data available for this report'),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _reportData.length,
                              itemBuilder: (context, index) {
                                final data = _reportData[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['label'] ?? 'Unknown Field',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(data['value'] ?? 'No Value'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }
}
