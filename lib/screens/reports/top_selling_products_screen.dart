import 'package:flutter/material.dart';
import '../../models/sales_reports.dart';
import '../../services/reports_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/reports/sales_chart_widget.dart';
import '../../utils/report_exporter.dart';
import '../../widgets/reports/pie_chart_widget.dart';
import '../../widgets/reports/bar_chart_widget.dart';
import '../../widgets/reports/report_filter_widget.dart';

class TopSellingProductsScreen extends StatefulWidget {
  const TopSellingProductsScreen({super.key});

  @override
  State<TopSellingProductsScreen> createState() => _TopSellingProductsScreenState();
}

class _TopSellingProductsScreenState extends State<TopSellingProductsScreen> {
  final _reportsService = ReportsService(Supabase.instance.client);
  final _currencyFormat = NumberFormat.currency(symbol: 'KSH ', decimalDigits: 2);
  List<TopSellingProduct> _products = [];
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
      final data = await _reportsService.getTopSellingProducts(_startDate, _endDate);
      setState(() {
        _products = data.map((json) => TopSellingProduct.fromJson(json)).toList();
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
        title: const Text('Top Selling Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReportFilterWidget(
                    title: 'Time Period',
                    selectedFilter: _selectedFilter,
                    onFilterChanged: _onFilterChanged,
                    filterOptions: _filterOptions,
                  ),
                  const SizedBox(height: 16),
                  if (_products.isNotEmpty) ...[
                    SizedBox(
                      height: 280,
                      child: PieChartWidget(
                        title: 'Category Distribution',
                        data: _getCategoryDistribution(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 280,
                      child: BarChartWidget(
                        title: 'Top 5 Products',
                        barGroups: _getTopProductsBarGroups(),
                        labels: _products.take(5).map((p) => p.itemName).toList(),
                        showCurrency: _selectedFilter == 'Revenue',
                      ),
                    ),
                  ] else
                    const Center(
                      child: Text('No data available for the selected period'),
                    ),
                ],
              ),
            ),
          ),
    );
  }

  List<FlSpot> _getRevenueDataPoints() {
    return _products.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.totalRevenue,
      );
    }).toList();
  }

  Future<void> _exportReport() async {
    try {
      await ReportExporter.exportSalesReport(
        data: _products,
        reportName: 'Top_Selling_Products',
        headers: [
          'Product Name',
          'Category',
          'Quantity Sold',
          'Total Revenue',
          'Profit Margin',
        ],
        fields: [
          'itemName',
          'category',
          'quantitySold',
          'totalRevenue',
          'profitMargin',
        ],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting report: $e')),
        );
      }
    }
  }

  void _sortProducts() {
    setState(() {
      switch (_selectedFilter) {
        case 'Revenue':
          _products.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
          break;
        case 'Quantity':
          _products.sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
          break;
        case 'Profit Margin':
          _products.sort((a, b) => b.profitMargin.compareTo(a.profitMargin));
          break;
      }
    });
  }

  List<CustomPieChartData> _getCategoryDistribution() {
    final categoryTotals = <String, double>{};
    double total = 0;

    for (final product in _products) {
      double value = switch (_selectedFilter) {
        'Revenue' => product.totalRevenue,
        'Quantity' => product.quantitySold.toDouble(),
        'Profit Margin' => product.profitMargin * product.totalRevenue,
        _ => 0.0,
      };
      
      categoryTotals[product.category] = (categoryTotals[product.category] ?? 0) + value;
      total += value;
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    return categoryTotals.entries.map((entry) {
      final index = categoryTotals.keys.toList().indexOf(entry.key);
      return CustomPieChartData(
        label: entry.key,
        value: entry.value,
        percentage: entry.value / total,
        color: colors[index % colors.length],
      );
    }).toList();
  }

  List<BarChartGroupData> _getTopProductsBarGroups() {
    return _products.take(5).toList().asMap().entries.map((entry) {
      double value = switch (_selectedFilter) {
        'Revenue' => entry.value.totalRevenue,
        'Quantity' => entry.value.quantitySold.toDouble(),
        'Profit Margin' => entry.value.profitMargin * 100,
        _ => 0.0,
      };

      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: value,
            color: Theme.of(context).primaryColor,
            width: 15,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }

  List<String> _getTopProductsLabels() {
    return _products.take(5).map((product) => product.itemName).toList();
  }

  Future<void> _selectDate(BuildContext context) async {
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
      await _loadReport();
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _sortProducts();
    });
  }
} 