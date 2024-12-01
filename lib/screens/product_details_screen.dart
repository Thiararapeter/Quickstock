import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../services/supabase_database.dart';
import '../widgets/add_part_dialog.dart';
import 'add_edit_part_screen.dart';
import 'package:intl/intl.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({Key? key, required this.productId}) : super(key: key);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late Future<InventoryItem?> _productFuture;
  late Future<List<InventoryItem>> _partsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _productFuture = SupabaseDatabase.instance.getItem(widget.productId);
    _partsFuture = SupabaseDatabase.instance.getProductParts(widget.productId);
  }

  Future<void> _showAddPartOptions() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Part',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.playlist_add),
                  title: const Text('Select Existing Part'),
                  onTap: () {
                    Navigator.pop(context, 'existing');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Create New Part'),
                  onTap: () {
                    Navigator.pop(context, 'new');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (choice == 'existing') {
      await _addExistingPart();
    } else if (choice == 'new') {
      await _createAndAddNewPart();
    }
  }

  Future<void> _addExistingPart() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddPartDialog(),
    );

    if (result != null && mounted) {
      try {
        await SupabaseDatabase.instance.addPartToProduct(
          widget.productId,
          result['partId'],
        );
        
        // Add history record
        await SupabaseDatabase.instance.addHistory(
          widget.productId,
          'PART_ADDED',
          'Added part to product',
          partId: result['partId'],
        );
        
        setState(() {
          _loadData();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding part: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _createAndAddNewPart() async {
    final result = await Navigator.push<InventoryItem>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditPartScreen(),
      ),
    );

    if (result != null && mounted) {
      try {
        await SupabaseDatabase.instance.addPartToProduct(
          widget.productId,
          result.id,
        );
        
        // Add history record
        await SupabaseDatabase.instance.addHistory(
          widget.productId,
          'PART_ADDED',
          'Added part to product',
          partId: result.id,
        );
        
        setState(() {
          _loadData();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding part: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _removePart(String partId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Part'),
        content: const Text('Are you sure you want to remove this part?'),
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
      try {
        await SupabaseDatabase.instance.removePartFromProduct(widget.productId, partId);
        
        // Add history record for part removal
        await SupabaseDatabase.instance.addHistory(
          widget.productId,
          'PART_REMOVED',
          'Removed part from product',
          partId: partId,
        );

        setState(() {
          _loadData();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Part removed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing part: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Product Details'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Details'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDetailsTab(),
            _buildHistoryTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddPartOptions,
          child: const Icon(Icons.add),
          tooltip: 'Add Part',
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<InventoryItem?>(
            future: _productFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const Center(child: Text('Product not found'));
              }

              final product = snapshot.data!;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInfoRow('Serial Number', product.serialNumber),
                      _buildInfoRow('Category', product.category),
                      _buildInfoRow('Condition', product.condition),
                      _buildInfoRow('Quantity', product.quantity.toString()),
                      _buildInfoRow('Purchase Price', 'KSH ${product.purchasePrice}'),
                      _buildInfoRow('Selling Price', 'KSH ${product.sellingPrice}'),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Parts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<InventoryItem>>(
            future: _partsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final parts = snapshot.data ?? [];

              if (parts.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No parts added to this product',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: parts.length,
                itemBuilder: (context, index) {
                  final part = parts[index];
                  return Card(
                    child: ListTile(
                      leading: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.build),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
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
                          ),
                        ],
                      ),
                      title: Text(part.name),
                      subtitle: Text('SN: ${part.serialNumber}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _removePart(part.id),
                        tooltip: 'Remove Part',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value.startsWith('\$') ? value.replaceFirst('\$', 'KSH ') : value),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseDatabase.instance.getProductHistory(widget.productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final history = snapshot.data ?? [];
        
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No History Available',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) => _buildHistoryItem(history[index]),
          ),
        );
      },
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final dateFormat = DateFormat('MMM d, y HH:mm');
    final createdAt = DateTime.parse(item['created_at']);
    final actionType = item['action_type'] as String;
    final description = item['description'] as String;
    
    IconData icon;
    Color color;
    
    switch (actionType) {
      case 'PRODUCT_CREATED':
        icon = Icons.add_box;
        color = Colors.green;
        break;
      case 'PRODUCT_UPDATED':
        icon = Icons.edit;
        color = Colors.blue;
        break;
      case 'PART_ADDED':
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case 'PART_REMOVED':
        icon = Icons.remove_circle;
        color = Colors.red;
        break;
      case 'PRICE_CHANGED':
        icon = Icons.attach_money;
        color = Colors.orange;
        break;
      case 'QUANTITY_CHANGED':
        icon = Icons.inventory;
        color = Colors.purple;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    // Safely access the inventory data
    final inventoryData = item['inventory'] as Map<String, dynamic>?;
    final partName = inventoryData?['name'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(description),
        subtitle: Text(dateFormat.format(createdAt)),
        trailing: partName != null
            ? Chip(
                label: Text(
                  partName,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.grey.shade200,
              )
            : null,
      ),
    );
  }
} 