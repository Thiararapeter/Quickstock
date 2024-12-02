import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'top_selling_products_screen.dart';
import 'category_performance_screen.dart';
import 'parts_analysis_screen.dart';
import 'sales_trend_screen.dart';
import 'product_performance_screen.dart';

class SalesReportsDashboard extends StatelessWidget {
  const SalesReportsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Reports'),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildReportCard(
            context,
            title: 'Top Selling Products',
            icon: Icons.trending_up,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TopSellingProductsScreen(),
              ),
            ),
          ),
          _buildReportCard(
            context,
            title: 'Category Performance',
            icon: Icons.category,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategoryPerformanceScreen(),
              ),
            ),
          ),
          _buildReportCard(
            context,
            title: 'Parts Analysis',
            icon: Icons.build,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PartsAnalysisScreen(),
              ),
            ),
          ),
          _buildReportCard(
            context,
            title: 'Sales Trends',
            icon: Icons.timeline,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SalesTrendScreen(),
              ),
            ),
          ),
          _buildReportCard(
            context,
            title: 'Product Performance',
            icon: Icons.analytics,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProductPerformanceScreen(),
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
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 