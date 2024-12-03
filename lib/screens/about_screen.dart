import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_info.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Quick Stock',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          FutureBuilder<String>(
            future: AppInfo.getVersionInfo(),
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? 'Version 1.0.201',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 24),
          _buildAboutContent(context),
        ],
      ),
    );
  }

  Widget _buildAboutContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About Quick Stock',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        const Text(
          'Quick Stock is an inventory management system designed to help businesses efficiently track and manage their stock, repairs, warranties, assets, and sales with comprehensive reporting capabilities.',
        ),
        const SizedBox(height: 24),
        Text(
          'Features',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildFeaturesList(),
        const SizedBox(height: 24),
        Text(
          'Contact',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _launchURL('https://thiarara.co.ke/contact-us'),
          child: Text(
            'Visit our contact page',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _launchURL('mailto:contact@thiara.co.ke'),
          child: Text(
            'contact@thiara.co.ke',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Copyright',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          ' 2024 Thiarara. All rights reserved.\n'
          'Quick Stock is proprietary software. Unauthorized copying, modification, distribution, or use is strictly prohibited.',
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• Product inventory management with barcode support'),
        Text('• Parts tracking and management'),
        Text('• Category organization'),
        Text('• Point of Sale (POS) system'),
        Text('• Sales tracking and management'),
        Text('• Repair service management'),
        Text('• Warranty tracking system'),
        Text('• Asset management'),
        Text('• Expense tracking'),
        Text('• Comprehensive reporting system'),
        Text('• Data export to Excel and PDF'),
        Text('• Real-time updates and sync'),
        Text('• Offline capabilities'),
        Text('• Multi-user support'),
        Text('• Data backup and recovery'),
      ],
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}