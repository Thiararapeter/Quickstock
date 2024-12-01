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
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import '../services/permission_handler.dart';
import 'package:printing/printing.dart';

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
    _requestStoragePermission();
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.status;
      final manageStatus = await Permission.manageExternalStorage.status;
      
      if (storageStatus.isDenied || manageStatus.isDenied) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Storage Permission Required'),
            content: const Text(
              'This app needs storage permission to save PDF files and manage repairs. Would you like to grant permission?'
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Permission.storage.request();
                  await Permission.manageExternalStorage.request();
                },
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        );
      }
    }
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
                                            builder: (dialogContext) => AlertDialog(
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
                                                      Navigator.pop(dialogContext);
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
                                                          icon: const Icon(Icons.download, size: 18),
                                                          onPressed: () => _generateAndSavePdf(repair),
                                                          tooltip: 'Download PDF',
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.print, size: 18),
                                                          onPressed: () => _printRepairDetails(repair),
                                                          tooltip: 'Print',
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

  Future<void> _generateAndSavePdf(RepairTicket repair) async {
    try {
      if (Platform.isAndroid) {
        // Check if we have permission
        if (!await PermissionService.checkStoragePermission()) {
          if (mounted) {
            final result = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Storage Permission Required'),
                  content: const Text(
                    'Storage permission is required to save PDFs. Would you like to grant permission now?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Grant Permission'),
                    ),
                  ],
                );
              },
            );

            if (result == true) {
              // Request permission
              final status = await Permission.storage.request();
              final manageStatus = await Permission.manageExternalStorage.request();
              
              if (!status.isGranted && !manageStatus.isGranted) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Permission denied. Cannot save PDF.'),
                      action: SnackBarAction(
                        label: 'Settings',
                        onPressed: () => AppSettings.openAppSettings(),
                      ),
                    ),
                  );
                }
                return;
              }
            } else {
              // User cancelled permission request
              return;
            }
          }
        }
      }

      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text('Repair Ticket Details', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              
              // Ticket Information
              pw.Text('Ticket Number: ${repair.ticketNumber}'),
              pw.Text('Tracking ID: ${repair.trackingId}'),
              pw.Divider(),
              
              // Customer Information
              pw.Text('Customer Details:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text('Name: ${repair.customerName}'),
              pw.Text('Phone: ${repair.customerPhone}'),
              pw.SizedBox(height: 10),
              
              // Device Information
              pw.Text('Device Details:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text('Device: ${repair.deviceType}'),
              pw.Text('Model: ${repair.deviceModel}'),
              pw.Text('Serial: ${repair.serialNumber}'),
              pw.SizedBox(height: 10),
              
              // Repair Information
              pw.Text('Repair Details:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text('Status: ${repair.status.label}'),
              pw.Text('Cost: KSH ${repair.estimatedCost.toStringAsFixed(2)}'),
              pw.Text('Created: ${DateFormat('MMM d, y').format(repair.dateCreated)}'),
              if (repair.dateCompleted != null)
                pw.Text('Completed: ${DateFormat('MMM d, y').format(repair.dateCompleted!)}'),
              pw.SizedBox(height: 10),
              
              // Problem and Diagnosis
              pw.Text('Problem:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(repair.problem),
              pw.SizedBox(height: 10),
              pw.Text('Diagnosis:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(repair.diagnosis.isEmpty ? 'Not provided' : repair.diagnosis),
              
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

      if (Platform.isAndroid) {
        // Get the downloads directory
        final directory = await getExternalStorageDirectory();
        if (directory == null) throw Exception('Could not access storage');

        // Use the actual Downloads folder path
        final downloadsPath = '/storage/emulated/0/Download';
        
        try {
          // Create downloads directory if it doesn't exist
          await Directory(downloadsPath).create(recursive: true);

          final file = File('$downloadsPath/repair_ticket_${repair.ticketNumber}.pdf');
          await file.writeAsBytes(await pdf.save());

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF saved to ${file.path}'),
                action: SnackBarAction(
                  label: 'Open',
                  onPressed: () => OpenFile.open(file.path),
                ),
              ),
            );
          }
        } catch (e) {
          throw Exception('Failed to save PDF: $e');
        }
      } else {
        // For other platforms, use FilePicker
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save PDF File',
          fileName: 'repair_ticket_${repair.ticketNumber}.pdf',
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (outputFile == null) {
          throw Exception('No save location selected');
        }

        if (!outputFile.toLowerCase().endsWith('.pdf')) {
          outputFile = '$outputFile.pdf';
        }

        final file = File(outputFile);
        await file.writeAsBytes(await pdf.save());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved to ${file.path}'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () => OpenFile.open(file.path),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildPdfSection(String title, List<pw.Widget> children) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      padding: const pw.EdgeInsets.all(16),
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ...children,
        ],
      ),
    );
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

  Future<void> _printRepairDetails(RepairTicket repair) async {
    try {
      final pdf = pw.Document();
      
      // Define a custom page format for 80mm thermal printer
      final receiptPageFormat = PdfPageFormat(
        204.0, // 72mm printable width
        double.infinity, // Dynamic height
        marginAll: 0, // Remove all margins
      );
      
      pdf.addPage(
        pw.Page(
          pageFormat: receiptPageFormat,
          build: (context) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8), // Add small horizontal padding only
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min, // Minimize vertical space
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header - remove extra spacing
                pw.Center(
                  child: pw.Text(
                    'Repair Ticket',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                
                // Ticket Info - reduce spacing
                pw.Center(
                  child: pw.Text(
                    repair.ticketNumber,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Tracking ID: ${repair.trackingId}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                _buildReceiptDivider(),
                
                // Customer Details
                _buildReceiptSection('Customer Details', [
                  _buildReceiptRow('Name', repair.customerName),
                  _buildReceiptRow('Phone', repair.customerPhone),
                ]),
                
                // Device Details
                _buildReceiptSection('Device Details', [
                  _buildReceiptRow('Type', repair.deviceType),
                  _buildReceiptRow('Model', repair.deviceModel),
                  _buildReceiptRow('Serial', repair.serialNumber),
                ]),
                
                // Repair Details
                _buildReceiptSection('Repair Details', [
                  _buildReceiptRow('Status', repair.status.label),
                  _buildReceiptRow('Cost', repair.formattedEstimatedCost),
                  _buildReceiptRow('Created', repair.formattedDateCreated),
                  if (repair.dateCompleted != null)
                    _buildReceiptRow('Completed', repair.formattedDateCompleted),
                ]),
                
                // Problem Description
                _buildReceiptSection('Problem', [
                  pw.Text(
                    repair.problem,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ]),
                
                if (repair.diagnosis.isNotEmpty)
                  _buildReceiptSection('Diagnosis', [
                    pw.Text(
                      repair.diagnosis,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ]),
                
                if (repair.technicianNotes?.isNotEmpty == true)
                  _buildReceiptSection('Technician Notes', [
                    pw.Text(
                      repair.technicianNotes!,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ]),
                
                // Footer
                _buildReceiptDivider(),
                pw.Center(
                  child: pw.Text(
                    'Track Your Repair Progress',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Use Ticket # or Tracking ID',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => await pdf.save(),
        name: 'Repair Receipt ${repair.ticketNumber}',
        format: receiptPageFormat,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Update the helper methods to reduce spacing
  pw.Widget _buildReceiptSection(String title, List<pw.Widget> children) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min, // Minimize vertical space
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2), // Reduce spacing
        ...children,
        _buildReceiptDivider(),
      ],
    );
  }

  pw.Widget _buildReceiptRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1), // Reduce bottom padding
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 60,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
          pw.Text(
            ': ',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReceiptDivider() {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 3), // Reduce vertical margins
      height: 1,
      color: PdfColors.grey300,
    );
  }
} 