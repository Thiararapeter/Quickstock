import 'package:flutter/material.dart';
import '../models/warranty.dart';
import '../models/inventory_item.dart';
import '../services/supabase_database.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import 'add_edit_item_screen.dart';

class WarrantyListScreen extends StatefulWidget {
  const WarrantyListScreen({super.key});

  @override
  State<WarrantyListScreen> createState() => _WarrantyListScreenState();
}

class _WarrantyListScreenState extends State<WarrantyListScreen> {
  List<Warranty> _warranties = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  final Map<String, InventoryItem> _items = {};

  @override
  void initState() {
    super.initState();
    _loadWarranties();
  }

  Future<void> _loadWarranties() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final warranties = await SupabaseDatabase.instance.getAllWarranties();
      
      // Clear existing items
      _items.clear();
      
      // Load associated items with error handling for each item
      for (var warranty in warranties) {
        try {
          final item = await SupabaseDatabase.instance.getItem(warranty.itemId);
          if (item != null) {
            _items[warranty.itemId] = item;
          } else {
            developer.log('Warning: Item not found for warranty ${warranty.id}');
          }
        } catch (e) {
          developer.log('Error loading item for warranty ${warranty.id}: $e');
          // Continue loading other items even if one fails
        }
      }
      
      if (mounted) {
        setState(() {
          // Filter out warranties with missing items
          _warranties = warranties.where((w) => _items.containsKey(w.itemId)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading warranties: $e', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = _getErrorMessage(e);
          _warranties = []; // Clear warranties on error
        });
        _showErrorSnackBar(_errorMessage);
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is PostgrestException) {
      if (error.message.contains('JWT')) {
        return 'Your session has expired. Please log in again.';
      }
      return 'Database error: ${error.message}';
    }
    return 'Failed to load warranties: ${error.toString()}';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadWarranties,
        ),
      ),
    );
  }

  Color _getStatusColor(Warranty warranty) {
    if (warranty.isExpired) {
      return Colors.red;
    } else if (warranty.isExpiringSoon) {
      return Colors.orange;
    }
    return Colors.green;
  }

  String _getStatusText(Warranty warranty) {
    if (warranty.isExpired) {
      return 'Expired';
    } else if (warranty.isExpiringSoon) {
      final daysLeft = warranty.endDate.difference(DateTime.now()).inDays;
      return 'Expires in $daysLeft days';
    }
    return 'Active';
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadWarranties,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No warranties found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Add warranties to your items in the inventory section to track them here',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _handleWarrantyUpdate(InventoryItem item) async {
    // Wait for navigation result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditItemScreen(item: item),
      ),
    );

    // If result is true (successful save), refresh the warranty list
    if (result == true) {
      _loadWarranties();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warranties'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadWarranties,
              tooltip: 'Refresh warranties',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : _warranties.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _loadWarranties,
                      child: ListView.builder(
                        itemCount: _warranties.length,
                        itemBuilder: (context, index) {
                          final warranty = _warranties[index];
                          final item = _items[warranty.itemId];
                          
                          if (item == null) {
                            return const SizedBox.shrink();
                          }
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SN: ${item.serialNumber}'),
                                  Text('Supplier: ${warranty.supplier}'),
                                  Text(
                                    'Expires: ${DateFormat('MMM dd, yyyy').format(warranty.endDate)}',
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(warranty).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getStatusColor(warranty),
                                  ),
                                ),
                                child: Text(
                                  _getStatusText(warranty),
                                  style: TextStyle(
                                    color: _getStatusColor(warranty),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(item.name),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Serial Number: ${item.serialNumber}'),
                                          const Divider(),
                                          Text('Start Date: ${DateFormat('MMM dd, yyyy').format(warranty.startDate)}'),
                                          Text('End Date: ${DateFormat('MMM dd, yyyy').format(warranty.endDate)}'),
                                          Text('Period: ${warranty.period}'),
                                          Text('Supplier: ${warranty.supplier}'),
                                          if (warranty.terms.isNotEmpty) ...[
                                            const Divider(),
                                            const Text(
                                              'Terms & Notes:',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(warranty.terms),
                                          ],
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context); // Close dialog
                                          _handleWarrantyUpdate(_items[warranty.itemId]!); // Pass the item
                                        },
                                        child: const Text('Edit'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
} 