import 'package:flutter/material.dart';
import 'reports/sales_reports_dashboard.dart';
import 'reports/expense_report_screen.dart';
import 'reports/repair_report_screen.dart';
import 'reports/asset_report_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReportCard(
            context,
            title: 'Sales Reports',
            icon: Icons.point_of_sale,
            description: 'View sales performance, trends, and analytics',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SalesReportsDashboard(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            context,
            title: 'Expense Reports',
            icon: Icons.account_balance_wallet,
            description: 'Track expenses and financial metrics',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ExpenseReportScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            context,
            title: 'Repair Reports',
            icon: Icons.build,
            description: 'Analyze repair service performance',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RepairReportScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            context,
            title: 'Asset Reports',
            icon: Icons.precision_manufacturing,
            description: 'Monitor asset utilization and value',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AssetReportScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 