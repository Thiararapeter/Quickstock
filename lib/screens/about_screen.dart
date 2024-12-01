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
      body: FutureBuilder<String>(
        future: AppInfo.getVersionInfo(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Quick Stock',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                snapshot.data!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildAboutContent(context),
            ],
          );
        },
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
          'Quick Stock is an inventory management system designed to help businesses efficiently track and manage their stock, repairs, warranties, and assets.',
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
          'Copyright',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          '© 2024 Thiarara. All rights reserved.\n'
          'Quick Stock is proprietary software. Unauthorized copying, modification, distribution, or use is strictly prohibited.',
        ),
        const SizedBox(height: 24),
        Text(
          'Third-Party Packages',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildPackagesList(),
        const SizedBox(height: 24),
        InkWell(
          onTap: () => _launchURL('https://github.com/Thiararapeter/Quick-stock-Inventory'),
          child: Text(
            'View source code on GitHub',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
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
      ],
    );
  }

  Widget _buildFeaturesList() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• Product inventory management'),
        Text('• Parts tracking'),
        Text('• Category organization'),
        Text('• Repair service management'),
        Text('• Warranty tracking'),
        Text('• Asset management'),
        Text('• Expense tracking'),
        Text('• Real-time updates'),
        Text('• Offline capabilities'),
      ],
    );
  }

  Widget _buildPackagesList() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• supabase_flutter for backend services'),
        Text('• package_info_plus for app information'),
        Text('• url_launcher for external links'),
        Text('• pdf and flutter_pdfview for PDF handling'),
        Text('• connectivity_plus for network status'),
        Text('• shared_preferences for local storage'),
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