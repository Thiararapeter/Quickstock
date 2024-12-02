import 'package:flutter/material.dart';
import '../../models/product_performance_metrics.dart';
import '../../services/reports_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../widgets/reports/pie_chart_widget.dart';
import '../../widgets/reports/bar_chart_widget.dart';
import '../../widgets/reports/report_filter_widget.dart';

class ProductPerformanceScreen extends StatefulWidget {
  const ProductPerformanceScreen({super.key});

  @override
  State<ProductPerformanceScreen> createState() => _ProductPerformanceScreenState();
}

class _ProductPerformanceScreenState extends State<ProductPerformanceScreen> {
  final _reportsService = ReportsService(Supabase.instance.client);
  final _currencyFormat = NumberFormat.currency(symbol: 'KSH ', decimalDigits: 2);
  List<ProductPerformanceMetrics> _products = [];
  bool _isLoading = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedFilter = 'Revenue';
  final List<String> _filterOptions = ['Revenue', 'Quantity', 'Profit Margin'];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final data = await _reportsService.getProductPerformanceMetrics(
        _startDate,
        _endDate,
      );
      setState(() {
        _products = data;
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
        title: const Text('Product Performance'),
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
          : _products.isEmpty
              ? const Center(child: Text('No data available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Card(
                      child: ExpansionTile(
                        title: Text(product.itemName),
                        subtitle: Text(
                          'Revenue: ${_currencyFormat.format(product.totalRevenue)}\n'
                          'Category: ${product.category}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  'Quantity Sold',
                                  product.quantitySold.toString(),
                                ),
                                _buildInfoRow(
                                  'Profit Margin',
                                  '${(product.profitMargin * 100).toStringAsFixed(1)}%',
                                ),
                                _buildInfoRow(
                                  'Revenue Share',
                                  '${product.revenueShare.toStringAsFixed(1)}%',
                                ),
                                _buildInfoRow(
                                  'Stock Turnover',
                                  product.stockTurnover.toStringAsFixed(2),
                                ),
                                if (product.daysToStockout != null)
                                  _buildInfoRow(
                                    'Days to Stockout',
                                    '${product.daysToStockout} days',
                                    color: product.daysToStockout! < 30
                                        ? Colors.red
                                        : null,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
} 