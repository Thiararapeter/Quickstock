import 'package:flutter/material.dart';
import '../../models/sales_reports.dart';
import '../../services/reports_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SalesTrendScreen extends StatefulWidget {
  const SalesTrendScreen({super.key});

  @override
  State<SalesTrendScreen> createState() => _SalesTrendScreenState();
}

class _SalesTrendScreenState extends State<SalesTrendScreen> {
  final _reportsService = ReportsService(Supabase.instance.client);
  final _currencyFormat = NumberFormat.currency(symbol: 'KSH ', decimalDigits: 2);
  final _dateFormat = DateFormat('MMM d, y');
  List<SalesTrendAnalysis> _trends = [];
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
      final data = await _reportsService.getSalesTrendAnalysis(_startDate, _endDate);
      setState(() {
        _trends = data.map((json) => SalesTrendAnalysis.fromJson(json)).toList();
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
        title: const Text('Sales Trends'),
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
          : _trends.isEmpty
              ? const Center(child: Text('No data available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trends.length,
                  itemBuilder: (context, index) {
                    final trend = _trends[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _dateFormat.format(trend.saleDate),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow('Daily Revenue', _currencyFormat.format(trend.dailyRevenue)),
                            _buildInfoRow('Items Sold', trend.itemsSold.toString()),
                            _buildInfoRow('Transactions', trend.transactionCount.toString()),
                            _buildInfoRow('Avg Transaction', _currencyFormat.format(trend.averageTransactionValue)),
                            _buildInfoRow('Unique Customers', trend.uniqueCustomers.toString()),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
} 