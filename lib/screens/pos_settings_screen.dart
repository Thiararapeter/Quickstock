import 'package:flutter/material.dart';
import '../models/pos_settings.dart';
import '../services/supabase_database.dart';
import 'package:uuid/uuid.dart';

class POSSettingsScreen extends StatefulWidget {
  const POSSettingsScreen({super.key});

  @override
  State<POSSettingsScreen> createState() => _POSSettingsScreenState();
}

class _POSSettingsScreenState extends State<POSSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _storeNameController;
  late TextEditingController _taglineController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _websiteController;
  late TextEditingController _returnPolicyController;
  late TextEditingController _repairHeaderController;
  late TextEditingController _repairFooterController;
  bool _showVAT = true;
  bool _showBarcode = true;
  bool _showQRCode = true;
  bool _showRepairQR = true;
  bool _showTicketBarcode = true;
  POSSettings? _settings;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSettings();
  }

  void _initializeControllers() {
    _storeNameController = TextEditingController();
    _taglineController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _websiteController = TextEditingController();
    _returnPolicyController = TextEditingController();
    _repairHeaderController = TextEditingController();
    _repairFooterController = TextEditingController();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await SupabaseDatabase.instance.getPOSSettings();
      if (settings != null) {
        setState(() {
          _settings = settings;
          _storeNameController.text = settings.storeName;
          _taglineController.text = settings.tagline ?? '';
          _phoneController.text = settings.phone ?? '';
          _addressController.text = settings.address ?? '';
          _websiteController.text = settings.website ?? '';
          _returnPolicyController.text = settings.returnPolicy ?? '';
          _showVAT = settings.showVAT;
          _showBarcode = settings.showBarcode;
          _showQRCode = settings.showQR;
          _repairHeaderController.text = settings.repairHeaderText ?? '';
          _repairFooterController.text = settings.repairFooterText ?? '';
          _showRepairQR = settings.showRepairQR;
          _showTicketBarcode = settings.showTicketBarcode;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userId = SupabaseDatabase.instance.supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final settings = POSSettings(
        id: _settings?.id ?? const Uuid().v4(),
        userId: userId,
        storeName: _storeNameController.text.trim(),
        tagline: _taglineController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        website: _websiteController.text.trim(),
        returnPolicy: _returnPolicyController.text.trim(),
        showVAT: _showVAT,
        showBarcode: _showBarcode,
        showQR: _showQRCode,
        repairHeaderText: _repairHeaderController.text.trim(),
        repairFooterText: _repairFooterController.text.trim(),
        showRepairQR: _showRepairQR,
        showTicketBarcode: _showTicketBarcode,
        createdAt: _settings?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updatedSettings = await SupabaseDatabase.instance.updatePOSSettings(settings);
      if (updatedSettings != null) {
        _settings = updatedSettings;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Settings'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Receipt Header',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _storeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Store Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Store name is required';
                        }
                        if (value.length > 100) {
                          return 'Store name must be less than 100 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _taglineController,
                      decoration: const InputDecoration(
                        labelText: 'Tagline',
                        border: OutlineInputBorder(),
                      ),
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
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Website',
                        border: OutlineInputBorder(),
                      ),
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
                      'Receipt Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Show VAT'),
                      subtitle: const Text('Include VAT calculation in receipt'),
                      value: _showVAT,
                      onChanged: (value) => setState(() => _showVAT = value),
                    ),
                    SwitchListTile(
                      title: const Text('Show Barcode'),
                      subtitle: const Text('Print barcode on receipt'),
                      value: _showBarcode,
                      onChanged: (value) => setState(() => _showBarcode = value),
                    ),
                    SwitchListTile(
                      title: const Text('Show QR Code'),
                      subtitle: const Text('Print QR code on receipt'),
                      value: _showQRCode,
                      onChanged: (value) => setState(() => _showQRCode = value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _returnPolicyController,
                      decoration: const InputDecoration(
                        labelText: 'Return Policy',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
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
                      'Repair Ticket Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _repairHeaderController,
                      decoration: const InputDecoration(
                        labelText: 'Repair Ticket Header',
                        border: OutlineInputBorder(),
                        helperText: 'Text to appear at the top of repair tickets',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _repairFooterController,
                      decoration: const InputDecoration(
                        labelText: 'Repair Ticket Footer',
                        border: OutlineInputBorder(),
                        helperText: 'Text to appear at the bottom of repair tickets',
                      ),
                      maxLines: 3,
                    ),
                    SwitchListTile(
                      title: const Text('Show QR Code'),
                      subtitle: const Text('Include QR code for repair tracking'),
                      value: _showRepairQR,
                      onChanged: (value) => setState(() => _showRepairQR = value),
                    ),
                    SwitchListTile(
                      title: const Text('Show Ticket Barcode'),
                      subtitle: const Text('Include barcode with ticket number'),
                      value: _showTicketBarcode,
                      onChanged: (value) => setState(() => _showTicketBarcode = value),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Settings'),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _taglineController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _returnPolicyController.dispose();
    _repairHeaderController.dispose();
    _repairFooterController.dispose();
    super.dispose();
  }
} 