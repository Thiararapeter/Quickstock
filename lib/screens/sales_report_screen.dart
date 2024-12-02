import 'package:flutter/material.dart';
import '../models/sales_report.dart';
import 'reports/base_report_screen.dart';
import 'package:intl/intl.dart';

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

  @override
  String getReportTitle() => 'Sales Report';

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
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildPaymentMethodsCard(),
          const SizedBox(height: 16),
          _buildTopProductsCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Total Sales: \$${_salesReport!.totalSales.toStringAsFixed(2)}'),
            Text('Items Sold: ${_salesReport!.totalItemsSold}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Methods',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._salesReport!.paymentMethodTotals.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  '${entry.key}: \$${entry.value.toStringAsFixed(2)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Products',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._salesReport!.topProducts.map(
              (product) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.itemName),
                    Text(
                      'Sold: ${product.quantitySold} | Total: \$${product.totalSales.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Divider(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 