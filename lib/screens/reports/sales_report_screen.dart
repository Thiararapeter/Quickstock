import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/sales_report.dart';
import '../../services/reports_service.dart';
import 'base_report_screen.dart';

class SalesReportScreen extends BaseReportScreen {
  const SalesReportScreen({super.key}) : super(title: 'Sales Report');

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends BaseReportScreenState<SalesReportScreen> {
  SalesReport? _salesReport;
  DateTime _selectedDate = DateTime.now();

  @override
  Future<void> loadReportData() async {
    final report = await reportsService.getDailySalesReport(_selectedDate);
    setState(() {
      _salesReport = report;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await loadReportData();
    }
  }

  @override
  Widget buildReportContent() {
    if (_salesReport == null) {
      return const Center(
        child: Text('No sales data available for the selected period'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Report for ${DateFormat('MMMM dd, yyyy').format(_selectedDate)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          buildSummaryCard(
            title: 'Sales Summary',
            rows: [
              MapEntry('Total Sales', currencyFormat.format(_salesReport!.totalSales)),
              MapEntry('Items Sold', _salesReport!.totalItemsSold.toString()),
              if (_salesReport!.totalItemsSold > 0)
                MapEntry(
                  'Average Sale',
                  currencyFormat.format(_salesReport!.totalSales / _salesReport!.totalItemsSold),
                ),
            ],
          ),
          // ... rest of your existing content ...
        ],
      ),
    );
  }
} 