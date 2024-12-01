import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/repair_ticket.dart';
import '../services/supabase_database.dart';

class AddEditRepairScreen extends StatefulWidget {
  final RepairTicket? ticket;

  const AddEditRepairScreen({super.key, this.ticket});

  @override
  State<AddEditRepairScreen> createState() => _AddEditRepairScreenState();
}

class _AddEditRepairScreenState extends State<AddEditRepairScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _deviceTypeController;
  late TextEditingController _deviceModelController;
  late TextEditingController _serialNumberController;
  late TextEditingController _problemController;
  late TextEditingController _diagnosisController;
  late TextEditingController _estimatedCostController;
  late TextEditingController _technicianNotesController;
  late TextEditingController _customerNotesController;
  RepairStatus _status = RepairStatus.pending;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController(text: widget.ticket?.customerName);
    _customerPhoneController = TextEditingController(text: widget.ticket?.customerPhone);
    _deviceTypeController = TextEditingController(text: widget.ticket?.deviceType);
    _deviceModelController = TextEditingController(text: widget.ticket?.deviceModel);
    _serialNumberController = TextEditingController(text: widget.ticket?.serialNumber);
    _problemController = TextEditingController(text: widget.ticket?.problem);
    _diagnosisController = TextEditingController(text: widget.ticket?.diagnosis);
    _estimatedCostController = TextEditingController(
      text: widget.ticket?.estimatedCost.toString() ?? '0.0',
    );
    _technicianNotesController = TextEditingController(
      text: widget.ticket?.technicianNotes,
    );
    _customerNotesController = TextEditingController(
      text: widget.ticket?.customerNotes,
    );
    if (widget.ticket != null) {
      _status = widget.ticket!.status;
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _deviceTypeController.dispose();
    _deviceModelController.dispose();
    _serialNumberController.dispose();
    _problemController.dispose();
    _diagnosisController.dispose();
    _estimatedCostController.dispose();
    _technicianNotesController.dispose();
    _customerNotesController.dispose();
    super.dispose();
  }

  Future<void> _saveTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final database = SupabaseDatabase.instance;
      final ticketNumber = await database.generateTicketNumber();
      final trackingId = database.generateTrackingId();

      final ticket = RepairTicket(
        id: widget.ticket?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        ticketNumber: widget.ticket?.ticketNumber ?? ticketNumber,
        trackingId: widget.ticket?.trackingId ?? trackingId,
        customerName: _customerNameController.text,
        customerPhone: _customerPhoneController.text,
        deviceType: _deviceTypeController.text,
        deviceModel: _deviceModelController.text,
        serialNumber: _serialNumberController.text,
        problem: _problemController.text,
        diagnosis: _diagnosisController.text,
        estimatedCost: double.tryParse(_estimatedCostController.text) ?? 0.0,
        status: _status,
        dateCreated: widget.ticket?.dateCreated ?? DateTime.now(),
        dateCompleted: _status == RepairStatus.completed ? DateTime.now() : null,
        usedPartIds: widget.ticket?.usedPartIds ?? [],
        technicianNotes: _technicianNotesController.text,
        customerNotes: _customerNotesController.text,
      );

      if (widget.ticket == null) {
        await database.createRepairTicket(ticket);
      } else {
        await database.updateRepairTicket(ticket);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticket == null ? 'New Repair Ticket' : 'Edit Repair Ticket'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Please enter customer name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _customerPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Phone',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Please enter customer phone' : null,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _deviceTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Device Type',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Please enter device type' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _deviceModelController,
                      decoration: const InputDecoration(
                        labelText: 'Device Model',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Please enter device model' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _serialNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Serial Number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Please enter serial number' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _problemController,
                      decoration: const InputDecoration(
                        labelText: 'Problem Description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Please enter problem description' : null,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _diagnosisController,
                      decoration: const InputDecoration(
                        labelText: 'Diagnosis',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _estimatedCostController,
                      decoration: const InputDecoration(
                        labelText: 'Estimated Cost',
                        border: OutlineInputBorder(),
                        prefixText: 'KSH ',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<RepairStatus>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: RepairStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _technicianNotesController,
                      decoration: const InputDecoration(
                        labelText: 'Technician Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _customerNotesController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveTicket,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          widget.ticket == null ? 'Create Ticket' : 'Update Ticket',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 