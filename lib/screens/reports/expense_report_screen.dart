import 'package:flutter/material.dart';
import '../../models/expense_report.dart';
import '../../services/reports_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/reports/pie_chart_widget.dart';
import '../../widgets/reports/bar_chart_widget.dart';

class ExpenseReportScreen extends StatefulWidget {
  const ExpenseReportScreen({super.key});

  @override
  State<ExpenseReportScreen> createState() => _ExpenseReportScreenState();
}

class _ExpenseReportScreenState extends State<ExpenseReportScreen> {
  final _reportsService = ReportsService(Supabase.instance.client);
  final _currencyFormat = NumberFormat.currency(symbol: 'KSH ', decimalDigits: 2);
  List<ExpenseReport> _expenses = [];
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
      final data = await _reportsService.getExpenseReport(_startDate, _endDate);
      setState(() {
        _expenses = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalExpenses = _expenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Report'),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Expenses',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currencyFormat.format(totalExpenses),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategorySummary(),
                  const SizedBox(height: 16),
                  if (_expenses.isNotEmpty) ...[
                    SizedBox(
                      height: 280,
                      child: PieChartWidget(
                        title: 'Expenses by Category',
                        data: _getCategoryDistribution(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 280,
                      child: BarChartWidget(
                        title: 'Daily Expenses',
                        barGroups: _getDailyExpenseGroups(),
                        labels: _getDailyLabels(),
                        showCurrency: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _expenses.length,
                      itemBuilder: (context, index) {
                        final expense = _expenses[index];
                        return Card(
                          child: ListTile(
                            title: Text(expense.description),
                            subtitle: Text(
                              '${expense.category}\n${DateFormat('MMM d, y').format(expense.date)}',
                            ),
                            trailing: Text(
                              _currencyFormat.format(expense.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
                  ] else
                    const Center(
                      child: Text('No expenses found for the selected period'),
                    ),
                ],
              ),
            ),
    );
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

  Future<void> _exportReport() async {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  List<CustomPieChartData> _getCategoryDistribution() {
    final categoryTotals = <String, double>{};
    double total = 0;

    for (final expense in _expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
      total += expense.amount;
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

  List<BarChartGroupData> _getDailyExpenseGroups() {
    final dailyTotals = <DateTime, double>{};
    
    // Group expenses by date
    for (final expense in _expenses) {
      final date = DateTime(expense.date.year, expense.date.month, expense.date.day);
      dailyTotals[date] = (dailyTotals[date] ?? 0) + expense.amount;
    }

    // Sort dates
    final sortedDates = dailyTotals.keys.toList()..sort();

    // Create bar groups
    return sortedDates.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: dailyTotals[entry.value]!,
            color: Theme.of(context).primaryColor,
            width: 15,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }

  List<String> _getDailyLabels() {
    final dates = _expenses.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet().toList()
      ..sort();
    return dates.map((date) => DateFormat('MMM d').format(date)).toList();
  }

  Widget _buildCategorySummary() {
    // Group expenses by category
    final categoryTotals = <String, double>{};
    for (final expense in _expenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...categoryTotals.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      _currencyFormat.format(entry.value),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
} 