import 'package:flutter/material.dart';
import '../../models/sales_reports.dart';
import '../../services/reports_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PartsAnalysisScreen extends StatefulWidget {
  const PartsAnalysisScreen({super.key});

  @override
  State<PartsAnalysisScreen> createState() => _PartsAnalysisScreenState();
}

class _PartsAnalysisScreenState extends State<PartsAnalysisScreen> {
  final _reportsService = ReportsService(Supabase.instance.client);
  final _currencyFormat = NumberFormat.currency(symbol: 'KSH ', decimalDigits: 2);
  List<PartsSalesAnalysis> _parts = [];
  bool _isLoading = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final data = await _reportsService.getPartsSalesAnalysis(_startDate, _endDate);
      setState(() {
        _parts = data.map((json) => PartsSalesAnalysis.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parts Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final DateTimeRange? picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                initialDateRange: DateTimeRange(
                  start: _startDate,
                  end: _endDate,
                ),
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked.start;
                  _endDate = picked.end;
                });
                _loadReport();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _parts.isEmpty
              ? const Center(child: Text('No data available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _parts.length,
                  itemBuilder: (context, index) {
                    final part = _parts[index];
                    return Card(
                      child: ListTile(
                        title: Text(part.partName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quantity Sold: ${part.quantitySold}'),
                            Text('Revenue: ${_currencyFormat.format(part.totalRevenue)}'),
                            Text('Current Stock: ${part.currentStock}'),
                          ],
                        ),
                        trailing: part.reorderSuggestion
                            ? Chip(
                                label: const Text('Reorder'),
                                backgroundColor: Colors.red[100],
                                labelStyle: const TextStyle(color: Colors.red),
                              )
                            : null,
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
} 