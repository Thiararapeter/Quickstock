import 'package:flutter/material.dart';
import '../models/repair_ticket.dart';
import '../services/supabase_database.dart';
import 'add_edit_repair_screen.dart';

enum SortOption {
  nameAZ('Name (A-Z)'),
  nameZA('Name (Z-A)'),
  costHighLow('Cost (High-Low)'),
  costLowHigh('Cost (Low-High)'),
  recentlyUpdated('Recently Updated'),
  oldestFirst('Oldest First');

  const SortOption(this.label);
  final String label;
}

class RepairsScreen extends StatefulWidget {
  const RepairsScreen({super.key});

  @override
  State<RepairsScreen> createState() => _RepairsScreenState();
}

class _RepairsScreenState extends State<RepairsScreen> {
  List<RepairTicket> _repairs = [];
  bool _isLoading = false;
  String _sortBy = 'date';  // Default sort
  bool _sortAscending = false;  // Default to most recent first

  @override
  void initState() {
    super.initState();
    _loadRepairs();
  }

  // Add sorting methods
  void _sortRepairs() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _repairs.sort((a, b) => _sortAscending
              ? a.customerName.compareTo(b.customerName)
              : b.customerName.compareTo(a.customerName));
          break;
        case 'cost':
          _repairs.sort((a, b) => _sortAscending
              ? a.estimatedCost.compareTo(b.estimatedCost)
              : b.estimatedCost.compareTo(a.estimatedCost));
          break;
        case 'date':
          _repairs.sort((a, b) => _sortAscending
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
        return Icons.access_time;
    }
  }

  Future<void> _loadRepairs() async {
    setState(() => _isLoading = true);
    try {
      final repairs = await SupabaseDatabase.instance.getRepairTickets();
      setState(() {
        _repairs = repairs;
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repairs'),
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
      body: _buildBody(),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return ListView.builder(
      itemCount: _repairs.length,
      itemBuilder: (context, index) {
        final repair = _repairs[index];
        return ListTile(
          title: Text('${repair.ticketNumber} - ${repair.customerName}'),
          subtitle: Text(repair.formattedDateCreated),
          trailing: Chip(
            label: Text(repair.status.label),
            backgroundColor: _getStatusColor(repair.status),
          ),
        );
      },
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
} 