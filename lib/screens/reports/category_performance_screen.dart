import 'package:flutter/material.dart';
import '../../models/sales_reports.dart';
import '../../services/reports_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CategoryPerformanceScreen extends StatefulWidget {
  const CategoryPerformanceScreen({super.key});

  @override
  State<CategoryPerformanceScreen> createState() => _CategoryPerformanceScreenState();
}

class _CategoryPerformanceScreenState extends State<CategoryPerformanceScreen> {
  final _reportsService = ReportsService(Supabase.instance.client);
  final _currencyFormat = NumberFormat.currency(symbol: 'KSH ', decimalDigits: 2);
  List<CategorySalesPerformance> _categories = [];
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
      final data = await _reportsService.getCategorySalesPerformance(_startDate, _endDate);
      setState(() {
        _categories = data.map((json) => CategorySalesPerformance.fromJson(json)).toList();
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
        title: const Text('Category Performance'),
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
          : _categories.isEmpty
              ? const Center(child: Text('No data available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.category,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow('Total Revenue', _currencyFormat.format(category.totalRevenue)),
                            _buildInfoRow('Items Sold', category.totalItemsSold.toString()),
                            _buildInfoRow('Unique Products', category.uniqueProducts.toString()),
                            _buildInfoRow('Average Price', _currencyFormat.format(category.averageItemPrice)),
                            _buildInfoRow('Profit', _currencyFormat.format(category.categoryProfit)),
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