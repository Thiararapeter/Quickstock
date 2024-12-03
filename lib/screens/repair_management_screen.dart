import 'package:flutter/material.dart';
import '../models/repair_ticket.dart';
import '../services/supabase_database.dart';
import 'package:intl/intl.dart';
import 'add_edit_repair_screen.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app_settings/app_settings.dart';
import 'package:printing/printing.dart';
import 'package:barcode/barcode.dart';

enum SortOption {
  nameAZ('Customer Name (A-Z)'),
  nameZA('Customer Name (Z-A)'),
  costHighLow('Cost (High-Low)'),
  costLowHigh('Cost (Low-High)'),
  recentlyUpdated('Recently Updated'),
  oldestFirst('Oldest First');

  const SortOption(this.label);
  final String label;
}

class RepairManagementScreen extends StatefulWidget {
  const RepairManagementScreen({super.key});

  @override
  State<RepairManagementScreen> createState() => _RepairManagementScreenState();
}

class _RepairManagementScreenState extends State<RepairManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<RepairTicket> _allRepairs = [];
  List<RepairTicket> _filteredRepairs = [];
  bool _isLoading = false;
  String _sortBy = 'date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadRepairs();
  }

  void _filterRepairs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRepairs = _allRepairs;
      } else {
        query = query.toLowerCase();
        _filteredRepairs = _allRepairs.where((repair) {
          return repair.customerName.toLowerCase().contains(query) ||
              repair.ticketNumber.toLowerCase().contains(query) ||
              repair.deviceType.toLowerCase().contains(query) ||
              repair.status.toString().toLowerCase().contains(query);
        }).toList();
      }
      _sortRepairs(); // Apply current sort to filtered results
    });
  }

  void _sortRepairs() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _filteredRepairs.sort((a, b) => _sortAscending
              ? a.customerName.compareTo(b.customerName)
              : b.customerName.compareTo(a.customerName));
          break;
        case 'cost':
          _filteredRepairs.sort((a, b) => _sortAscending
              ? a.estimatedCost.compareTo(b.estimatedCost)
              : b.estimatedCost.compareTo(a.estimatedCost));
          break;
        case 'date':
          _filteredRepairs.sort((a, b) => _sortAscending
              ? a.dateCreated.compareTo(b.dateCreated)
              : b.dateCreated.compareTo(a.dateCreated));
          break;
      }
    });
  }

  void _handleSort(SortOption option) {
    setState(() {
      switch (option) {
        case SortOption.nameAZ:
          _sortBy = 'name';
          _sortAscending = true;
          break;
        case SortOption.nameZA:
          _sortBy = 'name';
          _sortAscending = false;
          break;
        case SortOption.costHighLow:
          _sortBy = 'cost';
          _sortAscending = false;
          break;
        case SortOption.costLowHigh:
          _sortBy = 'cost';
          _sortAscending = true;
          break;
        case SortOption.recentlyUpdated:
          _sortBy = 'date';
          _sortAscending = false;
          break;
        case SortOption.oldestFirst:
          _sortBy = 'date';
          _sortAscending = true;
          break;
      }
      _sortRepairs();
    });
  }

  String _getSortType(SortOption option) {
    switch (option) {
      case SortOption.nameAZ:
      case SortOption.nameZA:
        return 'name';
      case SortOption.costHighLow:
      case SortOption.costLowHigh:
        return 'cost';
      case SortOption.recentlyUpdated:
      case SortOption.oldestFirst:
        return 'date';
    }
  }

  bool _isAscending(SortOption option) {
    switch (option) {
      case SortOption.nameAZ:
      case SortOption.costLowHigh:
      case SortOption.oldestFirst:
        return true;
      case SortOption.nameZA:
      case SortOption.costHighLow:
      case SortOption.recentlyUpdated:
        return false;
    }
  }

  IconData _getSortIcon(SortOption option) {
    switch (option) {
      case SortOption.nameAZ:
      case SortOption.nameZA:
        return Icons.sort_by_alpha;
      case SortOption.costHighLow:
      case SortOption.costLowHigh:
        return Icons.attach_money;
      case SortOption.recentlyUpdated:
      case SortOption.oldestFirst:
        return Icons.calendar_today;
    }
  }

  Future<void> _loadRepairs() async {
    setState(() => _isLoading = true);
    try {
      final repairs = await SupabaseDatabase.instance.getRepairTickets();
      setState(() {
        _allRepairs = repairs;
        _filteredRepairs = repairs;
        _sortRepairs(); // Apply current sort after loading
      });
    } catch (e) {
      _showSnackBar('Error loading repairs: $e', true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Management'),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: _handleSort,
            itemBuilder: (BuildContext context) {
              return SortOption.values.map((SortOption option) {
                return PopupMenuItem<SortOption>(
                  value: option,
                  child: Row(
                    children: [
                      Icon(
                        _getSortIcon(option),
                        color: _sortBy == _getSortType(option) &&
                                _sortAscending == _isAscending(option)
                            ? Theme.of(context).primaryColor
                            : null,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(option.label),
                      if (_sortBy == _getSortType(option) &&
                          _sortAscending == _isAscending(option))
                        const Spacer()
                      else
                        const SizedBox.shrink(),
                      if (_sortBy == _getSortType(option) &&
                          _sortAscending == _isAscending(option))
                        Icon(
                          Icons.check,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRepairs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by ticket number, tracking ID, or customer...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _filterRepairs,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRepairs.isEmpty
                    ? const Center(child: Text('No repair tickets found'))
                    : ListView.builder(
                        itemCount: _filteredRepairs.length,
                        itemBuilder: (context, index) {
                          final repair = _filteredRepairs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: repair.ticketNumber));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Ticket number copied to clipboard'),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(16),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            repair.ticketNumber,
                                            style: TextStyle(
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.copy,
                                            size: 14,
                                            color: Theme.of(context).primaryColor.withOpacity(0.7),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(repair.customerName),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: repair.trackingId));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Tracking ID copied to clipboard'),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(16),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Row(
                                          children: [
                                            Text(
                                              'Tracking ID: ${repair.trackingId}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.copy,
                                              size: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Device: ${repair.deviceType} ${repair.deviceModel}'),
                                  Text('Created: ${DateFormat('MMM dd, yyyy').format(repair.dateCreated)}'),
                                  Row(
                                    children: [
                                      Text('Status: '),
                                      TextButton.icon(
                                        icon: Icon(Icons.edit, size: 16),
                                        label: Text(repair.status.label),
                                        style: TextButton.styleFrom(
                                          backgroundColor: _getStatusColor(repair.status).withOpacity(0.2),
                                          foregroundColor: _getStatusColor(repair.status),
                                        ),
                                        onPressed: () {
                                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Update Status'),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: RepairStatus.values.map((status) {
                                                  return ListTile(
                                                    leading: Icon(
                                                      Icons.circle,
                                                      color: _getStatusColor(status),
                                                      size: 16,
                                                    ),
                                                    title: Text(status.label),
                                                    selected: repair.status == status,
                                                    onTap: () async {
                                                      Navigator.pop(context);
                                                      try {
                                                        setState(() => _isLoading = true);
                                                        final updatedTicket = repair.copyWith(
                                                          status: status,
                                                          dateCompleted: status == RepairStatus.completed 
                                                              ? DateTime.now() 
                                                              : repair.dateCompleted,
                                                        );
                                                        await SupabaseDatabase.instance.updateRepairTicket(updatedTicket);
                                                        
                                                        if (mounted) {
                                                          scaffoldMessenger.showSnackBar(
                                                            SnackBar(
                                                              content: Row(
                                                                children: [
                                                                  Icon(Icons.check_circle, color: Colors.white),
                                                                  const SizedBox(width: 8),
                                                                  Expanded(
                                                                    child: Column(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        Text('Status Updated'),
                                                                        Text(
                                                                          'Ticket ${repair.ticketNumber} is now ${status.label}',
                                                                          style: const TextStyle(fontSize: 12),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              backgroundColor: _getStatusColor(status),
                                                              duration: const Duration(seconds: 3),
                                                              behavior: SnackBarBehavior.floating,
                                                              margin: const EdgeInsets.all(16),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                          );
                                                          await _loadRepairs(); // Refresh the list
                                                        }
                                                      } catch (e) {
                                                        if (mounted) {
                                                          scaffoldMessenger.showSnackBar(
                                                            SnackBar(
                                                              content: Row(
                                                                children: [
                                                                  Icon(Icons.error, color: Colors.white),
                                                                  const SizedBox(width: 8),
                                                                  Expanded(
                                                                    child: Text('Error updating status: $e'),
                                                                  ),
                                                                ],
                                                              ),
                                                              backgroundColor: Colors.red,
                                                              behavior: SnackBarBehavior.floating,
                                                              margin: const EdgeInsets.all(16),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      } finally {
                                                        if (mounted) {
                                                          setState(() => _isLoading = false);
                                                        }
                                                      }
                                                    },
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (String action) async {
                                  switch (action) {
                                    case 'edit':
                                      final result = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddEditRepairScreen(ticket: repair),
                                        ),
                                      );
                                      if (result == true && mounted) {
                                        _loadRepairs();
                                      }
                                      break;
                                    case 'view':
                                      await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          titlePadding: EdgeInsets.zero,
                                          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                                          title: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Theme.of(context).dividerColor,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'Repair Details - ${repair.ticketNumber}',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(Icons.share, size: 18),
                                                          onPressed: () {
                                                            Share.share(
                                                              '''
Repair Ticket Details:
Ticket: ${repair.ticketNumber}
Customer: ${repair.customerName}
Phone: ${repair.customerPhone}
Device: ${repair.deviceType}
Model: ${repair.deviceModel}
Serial: ${repair.serialNumber}
Status: ${repair.status.label}
Cost: ${repair.formattedEstimatedCost}
Created: ${repair.formattedDateCreated}
${repair.dateCompleted != null ? 'Completed: ${repair.formattedDateCompleted}\n' : ''}
Problem: ${repair.problem}
${repair.diagnosis.isNotEmpty ? 'Diagnosis: ${repair.diagnosis}\n' : ''}
${repair.technicianNotes?.isNotEmpty == true ? 'Technician Notes: ${repair.technicianNotes}\n' : ''}
                                                              ''',
                                                              subject: 'Repair Ticket ${repair.ticketNumber}',
                                                            );
                                                          },
                                                          tooltip: 'Share',
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.print, size: 18),
                                                          onPressed: () => _printRepairDetails(repair),
                                                          tooltip: 'Print/Save',
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.download, size: 18),
                                                          onPressed: () async {
                                                            await _printRepairDetails(repair); // This now handles both print and save
                                                          },
                                                          tooltip: 'Download',
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.message, size: 18),
                                                          onPressed: () => _generateAndSharePdf(repair, shareOnWhatsApp: true),
                                                          tooltip: 'Share via WhatsApp',
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    Clipboard.setData(ClipboardData(text: repair.trackingId));
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Tracking ID copied to clipboard'),
                                                        backgroundColor: Colors.green,
                                                        behavior: SnackBarBehavior.floating,
                                                        margin: const EdgeInsets.all(16),
                                                        duration: const Duration(seconds: 2),
                                                      ),
                                                    );
                                                  },
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.qr_code, size: 14, color: Colors.grey[600]),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Tracking ID: ${repair.trackingId}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        Icons.copy,
                                                        size: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _detailRow('Customer', repair.customerName),
                                                _detailRow('Phone', repair.customerPhone),
                                                _detailRow('Device', repair.deviceType),
                                                _detailRow('Model', repair.deviceModel),
                                                _detailRow('Serial', repair.serialNumber),
                                                _detailRow('Status', repair.status.label),
                                                _detailRow('Cost', repair.formattedEstimatedCost),
                                                _detailRow('Created', repair.formattedDateCreated),
                                                if (repair.dateCompleted != null)
                                                  _detailRow('Completed', repair.formattedDateCompleted),
                                                const SizedBox(height: 8),
                                                const Text('Problem:', style: TextStyle(fontWeight: FontWeight.bold)),
                                                Text(repair.problem),
                                                if (repair.diagnosis.isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  const Text('Diagnosis:', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  Text(repair.diagnosis),
                                                ],
                                                if (repair.technicianNotes?.isNotEmpty == true) ...[
                                                  const SizedBox(height: 8),
                                                  const Text('Technician Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  Text(repair.technicianNotes!),
                                                ],
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Close'),
                                            ),
                                            if (repair.status != RepairStatus.cancelled && repair.status != RepairStatus.delivered)
                                              TextButton(
                                                onPressed: () async {
                                                  final result = await Navigator.push<bool>(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => AddEditRepairScreen(ticket: repair),
                                                    ),
                                                  );
                                                  if (result == true && mounted) {
                                                    Navigator.pop(context);
                                                    _loadRepairs();
                                                  }
                                                },
                                                child: const Text('Edit'),
                                              ),
                                          ],
                                        ),
                                      );
                                      break;
                                    case 'delete':
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Repair Ticket'),
                                          content: Text('Are you sure you want to delete repair ticket ${repair.ticketNumber}?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true && mounted) {
                                        try {
                                          await SupabaseDatabase.instance.deleteRepairTicket(repair.id);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Repair ticket deleted successfully'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                            _loadRepairs();
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error deleting repair ticket: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                      break;
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility),
                                        SizedBox(width: 8),
                                        Text('View Details'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'repair_fab',
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditRepairScreen(),
            ),
          );
          if (result == true && mounted) {
            _loadRepairs();  // Refresh the list if a repair was added
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Repair'),
      ),
    );
  }

  Color _getStatusColor(RepairStatus status) {
    switch (status) {
      case RepairStatus.pending:
        return Colors.orange.shade400;
      case RepairStatus.inProgress:
        return Colors.blue.shade400;
      case RepairStatus.completed:
        return Colors.green.shade400;
      case RepairStatus.delivered:
        return Colors.purple.shade300;
      case RepairStatus.cancelled:
        return Colors.red.shade400;
      case RepairStatus.waitingForParts:
        return Colors.amber.shade400;
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _printRepairDetails(RepairTicket repair) async {
    try {
      final pdf = await _generateRepairTicket(repair);
      
      // Get the downloads directory
      final downloadsPath = Directory('/storage/emulated/0/Download/QuickStock/Repairs');
      await downloadsPath.create(recursive: true);

      // Save the file
      final file = File('${downloadsPath.path}/Repair_${repair.ticketNumber}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Print if needed
      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        format: const PdfPageFormat(
          58 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 2 * PdfPageFormat.mm,
        ),
        name: 'Repair-${repair.ticketNumber}',
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Repair ticket saved to Downloads/QuickStock/Repairs folder'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
        Navigator.of(context).pop(); // Close details dialog
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing repair ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<pw.Document> _generateRepairTicket(RepairTicket repair) async {
    final pdf = pw.Document();
    
    // Load fonts
    final regularFont = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    // Get POS settings
    final settings = await SupabaseDatabase.instance.getPOSSettings();

    // Generate QR code data
    final qrData = {
      'ticket': repair.ticketNumber,
      'tracking': repair.trackingId,
      'customer': repair.customerName,
      'device': repair.deviceType,
      'status': repair.status.name,
    };

    // Create barcode
    final barcode = Barcode.code128();
    final barcodeData = await barcode.toSvg(repair.ticketNumber, width: 200, height: 40);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          58 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 2 * PdfPageFormat.mm,
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            // Store Header
            pw.Text(
              settings?.storeName ?? 'QUICK STOCK',
              style: pw.TextStyle(font: boldFont, fontSize: 10),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              settings?.tagline ?? 'Your One-Stop Shop',
              style: pw.TextStyle(font: regularFont, fontSize: 7),
            ),
            pw.Text(
              settings?.phone ?? '+254 123 456 789',
              style: pw.TextStyle(font: regularFont, fontSize: 7),
            ),
            pw.Text(
              settings?.address ?? 'Your Address Here',
              style: pw.TextStyle(font: regularFont, fontSize: 7),
            ),
            pw.SizedBox(height: 2),
            pw.Divider(thickness: 0.5),

            // Repair Header with Barcode
            pw.Text(
              'Repair Ticket',
              style: pw.TextStyle(font: boldFont, fontSize: 10),
            ),
            if (settings?.showTicketBarcode == true) ...[
              pw.SizedBox(height: 5),
              pw.SvgImage(svg: barcodeData),
            ],
            pw.SizedBox(height: 2),
            pw.Text(
              'TICKET${repair.ticketNumber}',
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
            pw.Text(
              'Tracking ID: ${repair.trackingId}',
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
            pw.SizedBox(height: 2),
            pw.Divider(thickness: 0.5),

            // Customer Details
            pw.Text(
              'Customer Details',
              style: pw.TextStyle(font: boldFont, fontSize: 9),
            ),
            pw.Text(
              'Name    : ${repair.customerName}',
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
            pw.Text(
              'Phone   : ${repair.customerPhone}',
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
            pw.SizedBox(height: 2),
            pw.Divider(thickness: 0.5),

            // Device Details
            pw.Text(
              'Device Details',
              style: pw.TextStyle(font: boldFont, fontSize: 9),
            ),
            pw.Text(
              'Type    : ${repair.deviceType}',
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
            pw.Text(
              'Model   : ${repair.deviceModel}',
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
            pw.Text(
              'Serial  : ${repair.serialNumber}',
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
            pw.SizedBox(height: 2),
            pw.Divider(thickness: 0.5),

            // Repair Details
            pw.Text(
              'Repair Details',
              style: pw.TextStyle(font: boldFont, fontSize: 9),
            ),
            pw.Text(
              'Status  : ${repair.status.name}',
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
            pw.Text(
              'Cost    : KSH ${repair.estimatedCost.toStringAsFixed(2)}',
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
            pw.Text(
              'Created : ${DateFormat('MMM dd, yyyy').format(repair.dateCreated)}',
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
            if (repair.dateCompleted != null)
              pw.Text(
                'Completed: ${DateFormat('MMM dd, yyyy').format(repair.dateCompleted!)}',
                style: pw.TextStyle(font: regularFont, fontSize: 8),
              ),
            pw.SizedBox(height: 2),
            pw.Divider(thickness: 0.5),

            // Problem and Diagnosis
            pw.Text(
              'Problem',
              style: pw.TextStyle(font: boldFont, fontSize: 9),
            ),
            pw.Text(
              repair.problem,
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Diagnosis',
              style: pw.TextStyle(font: boldFont, fontSize: 9),
            ),
            pw.Text(
              repair.diagnosis ?? 'Pending',
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
            pw.SizedBox(height: 2),
            pw.Divider(thickness: 0.5),

            // QR Code
            if (settings?.showRepairQR ?? true) ...[
              pw.BarcodeWidget(
                data: qrData.toString(),
                barcode: pw.Barcode.qrCode(),
                width: 50,
                height: 50,
              ),
              pw.SizedBox(height: 4),
            ],

            // Footer
            pw.Text(
              'Track Your Repair Progress',
              style: pw.TextStyle(font: boldFont, fontSize: 8),
            ),
            pw.Text(
              'Use Ticket # or Tracking ID',
              style: pw.TextStyle(font: regularFont, fontSize: 7),
            ),
            if (settings?.website != null)
              pw.Text(
                settings!.website!,
                style: pw.TextStyle(font: regularFont, fontSize: 7),
              ),

            // Custom Footer Text
            if (settings?.repairFooterText != null) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                settings!.repairFooterText!,
                style: pw.TextStyle(font: regularFont, fontSize: 7),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );

    return pdf;
  }

  Future<void> _generateAndSharePdf(RepairTicket repair, {bool shareOnWhatsApp = false}) async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ... existing header content ...
              
              // Add notes if they exist
              if (repair.technicianNotes?.isNotEmpty == true) ...[
                pw.SizedBox(height: 10),
                pw.Text('Technician Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(repair.technicianNotes!),
              ],
              if (repair.customerNotes?.isNotEmpty == true) ...[
                pw.SizedBox(height: 10),
                pw.Text('Customer Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(repair.customerNotes!),
              ],
              
              // Footer with tracking instructions
              pw.Spacer(),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Track Your Repair Progress:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('Use either of these to check your repair status:'),
                    pw.Text('• Ticket Number: ${repair.ticketNumber}'),
                    pw.Text('• Tracking ID: ${repair.trackingId}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      // Save PDF to temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/repair_ticket_${repair.ticketNumber}.pdf');
      await file.writeAsBytes(await pdf.save());

      if (shareOnWhatsApp) {
        // Check if WhatsApp is installed
        final whatsappUrl = Uri.parse("whatsapp://send");
        if (await canLaunchUrl(whatsappUrl)) {
          // Share PDF file via WhatsApp
          await Share.shareXFiles(
            [XFile(file.path)],
            subject: 'Repair Ticket ${repair.ticketNumber}',
            text: 'Repair Ticket Details',
            sharePositionOrigin: const Rect.fromLTWH(0, 0, 10, 10),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('WhatsApp not installed')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 