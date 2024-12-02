import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/repair_report.dart';
import '../../services/supabase_database.dart';
import 'base_report_screen.dart';

class RepairReportScreen extends BaseReportScreen {
  const RepairReportScreen({super.key}) : super(title: 'Repair Report');

  @override
  State<RepairReportScreen> createState() => _RepairReportScreenState();
}

class _RepairReportScreenState extends BaseReportScreenState<RepairReportScreen> {
  List<RepairReport> _reports = [];
  final _currencyFormat = NumberFormat.currency(symbol: 'KSH ');
  final _percentFormat = NumberFormat.percentPattern();

  @override
  Future<void> loadReportData() async {
    final reports = await SupabaseDatabase.instance.getRepairReport(
      startDate,
      endDate,
    );
    setState(() {
      _reports = reports;
    });
  }

  @override
  Widget buildReportContent() {
    if (_reports.isEmpty) {
      return const Center(
        child: Text('No repair data available for the selected period'),
      );
    }

    final totalRevenue = _reports.fold<double>(
      0,
      (sum, report) => sum + report.totalRevenue,
    );

    final totalTickets = _reports.fold<int>(
      0,
      (sum, report) => sum + report.ticketCount,
    );

    final averageCompletionRate = _reports.fold<double>(
      0,
      (sum, report) => sum + report.repairCompletionRate,
    ) / _reports.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _buildSummaryRow('Total Revenue', _currencyFormat.format(totalRevenue)),
                _buildSummaryRow('Total Tickets', totalTickets.toString()),
                _buildSummaryRow(
                  'Average Completion Rate',
                  _percentFormat.format(averageCompletionRate / 100),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                for (final report in _reports) ...[
                  _buildStatusRow(report),
                  const Divider(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(RepairReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          report.status.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tickets: ${report.ticketCount}'),
                Text('Revenue: ${_currencyFormat.format(report.totalRevenue)}'),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Avg. Cost: ${_currencyFormat.format(report.averageRepairCost)}',
                ),
                Text(
                  'Completion: ${_percentFormat.format(report.repairCompletionRate / 100)}',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
} 