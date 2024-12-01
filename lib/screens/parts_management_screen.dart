import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../services/supabase_database.dart';
import 'add_edit_part_screen.dart';
import '../widgets/add_part_dialog.dart';
import 'package:intl/intl.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow(this.label, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class HistoryRow extends StatelessWidget {
  final String action;
  final String description;
  final DateTime date;

  const HistoryRow(this.action, this.description, this.date, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                action,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(date),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          Text(
            description,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class NoDataRow extends StatelessWidget {
  final String message;

  const NoDataRow(this.message, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class PartsManagementScreen extends StatefulWidget {
  const PartsManagementScreen({Key? key}) : super(key: key);

  @override
  _PartsManagementScreenState createState() => _PartsManagementScreenState();
}

class _PartsManagementScreenState extends State<PartsManagementScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _productsWithParts = [];
  List<InventoryItem> _unattachedParts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      
      final items = await SupabaseDatabase.instance.getAllItems();
      
      final List<Map<String, dynamic>> productsData = [];
      final unattachedParts = <InventoryItem>[];

      for (final item in items) {
        if (item.category == 'Parts') {
          unattachedParts.add(item);
        } else {
          final parts = await SupabaseDatabase.instance.getProductParts(item.id);
          if (parts.isNotEmpty) {
            productsData.add({
              'product': item,
              'parts': parts,
            });
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _productsWithParts = productsData;
        _unattachedParts = unattachedParts;
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error loading data: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _addPartToProduct(InventoryItem product) async {
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => const AddPartDialog(),
      );

      if (result != null && mounted) {
        await SupabaseDatabase.instance.addPartToProduct(
          product.id,
          result['partId'],
        );
        
        await SupabaseDatabase.instance.addHistory(
          product.id,
          'PART_ADDED',
          'Added part to product',
          partId: result['partId'],
        );
        
        _showSuccessSnackBar('Part added successfully');
        _loadData();
      }
    } catch (e) {
      _showErrorSnackBar('Error adding part: $e');
    }
  }

  Future<void> _createAndAddPart(InventoryItem product) async {
    try {
      final result = await Navigator.push<InventoryItem>(
        context,
        MaterialPageRoute(
          builder: (context) => const AddEditPartScreen(),
        ),
      );

      if (result != null && mounted) {
        await SupabaseDatabase.instance.addPartToProduct(
          product.id,
          result.id,
        );
        
        await SupabaseDatabase.instance.addHistory(
          product.id,
          'PART_ADDED',
          'Added part to product',
          partId: result.id,
        );
        
        _showSuccessSnackBar('Part created and added successfully');
        _loadData();
      }
    } catch (e) {
      _showErrorSnackBar('Error creating and adding part: $e');
    }
  }

  Future<void> _removePart(InventoryItem product, InventoryItem part) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Part'),
          content: Text('Are you sure you want to remove "${part.name}" from "${product.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await SupabaseDatabase.instance.removePartFromProduct(
          product.id,
          part.id,
        );
        _showSuccessSnackBar('Part removed successfully');
        _loadData();
      }
    } catch (e) {
      _showErrorSnackBar('Error removing part: $e');
    }
  }

  void _showAddPartOptions(InventoryItem product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Part'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Select Existing Part'),
                onTap: () {
                  Navigator.pop(context);
                  _addPartToProduct(product);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Create New Part'),
                onTap: () {
                  Navigator.pop(context);
                  _createAndAddPart(product);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePartAction(String action, InventoryItem part) async {
    switch (action) {
      case 'view':
        _viewPartDetails(part);
        break;
      case 'edit':
        await _editPart(part);
        break;
      case 'delete':
        await _deletePart(part);
        break;
    }
  }

  void _viewPartDetails(InventoryItem part) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(part.name),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Serial Number: ${part.serialNumber}'),
                        Text('Purchase Price: KSH ${part.purchasePrice.toStringAsFixed(2)}'),
                        Text('Selling Price: KSH ${part.sellingPrice.toStringAsFixed(2)}'),
                        Text('Quantity: ${part.quantity}'),
                        Text('Condition: ${part.condition}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Part history section
                const Text(
                  'History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: SupabaseDatabase.instance.getPartHistory(part.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('No history available');
                    }

                    final history = snapshot.data!.map((item) {
                      final actionType = item['action_type'] as String? ?? 'Unknown Action';
                      final description = item['description'] as String? ?? 'No description';
                      final createdAt = DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();
                      
                      return {
                        'actionType': actionType,
                        'description': description,
                        'createdAt': createdAt,
                      };
                    }).toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return ListTile(
                          title: Text(item['actionType'] as String),
                          subtitle: Text(item['description'] as String),
                          trailing: Text(
                            DateFormat('MMM d, y HH:mm')
                                .format(item['createdAt'] as DateTime),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Future<void> _editPart(InventoryItem part) async {
    final result = await Navigator.push<InventoryItem>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPartScreen(part: part),
      ),
    );

    if (result != null) {
      _showSuccessSnackBar('Part updated successfully');
      _loadData();
    }
  }

  Future<void> _deletePart(InventoryItem part) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Part'),
        content: Text('Are you sure you want to delete "${part.name}"?'),
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

    if (confirm == true) {
      try {
        await SupabaseDatabase.instance.deleteItem(part.id);
        _showSuccessSnackBar('Part deleted successfully');
        _loadData();
      } catch (e) {
        _showErrorSnackBar('Error deleting part: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parts Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_unattachedParts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Available Parts',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _unattachedParts.length,
                      itemBuilder: (context, index) {
                        final part = _unattachedParts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.build, size: 24),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    part.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'PART',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SN: ${part.serialNumber}'),
                                Text(
                                  'Status: Available',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'KSH ${part.sellingPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) => _handlePartAction(value, part),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'view',
                                      child: ListTile(
                                        leading: Icon(Icons.visibility),
                                        title: Text('View Details'),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit),
                                        title: Text('Edit'),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete),
                                        title: Text('Delete'),
                                        textColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 32),
                  ],
                  if (_productsWithParts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Products with Parts',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _productsWithParts.length,
                      itemBuilder: (context, index) {
                        final productData = _productsWithParts[index];
                        final product = productData['product'] as InventoryItem;
                        final parts = productData['parts'] as List<InventoryItem>;

                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: ExpansionTile(
                            title: Text(product.name),
                            subtitle: Text(
                              'SN: ${product.serialNumber}\n'
                              'Parts: ${parts.length}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _showAddPartOptions(product),
                              tooltip: 'Add Part',
                            ),
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: parts.length,
                                itemBuilder: (context, partIndex) {
                                  final part = parts[partIndex];
                                  return ListTile(
                                    leading: const Icon(Icons.build),
                                    title: Row(
                                      children: [
                                        Expanded(child: Text(part.name)),
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'PART',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text('SN: ${part.serialNumber}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () => _removePart(product, part),
                                      tooltip: 'Remove Part',
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  if (_unattachedParts.isEmpty && _productsWithParts.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No parts available',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddEditPartScreen(),
                                ),
                              );
                              _loadData();
                            },
                            child: const Text('Create New Part'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditPartScreen(),
            ),
          );
          _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Part'),
      ),
    );
  }
} 