import 'package:flutter/material.dart';
import '../services/supabase_database.dart';
import 'package:intl/intl.dart';

class ProductHistoryScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const ProductHistoryScreen({
    Key? key,
    required this.productId,
    required this.productName,
  }) : super(key: key);

  @override
  State<ProductHistoryScreen> createState() => _ProductHistoryScreenState();
}

class _ProductHistoryScreenState extends State<ProductHistoryScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() => _isLoading = true);
      final history = await SupabaseDatabase.instance.getProductHistory(widget.productId);
      setState(() => _history = history);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(description),
        subtitle: Text(dateFormat.format(createdAt)),
        trailing: item['inventory'] != null
            ? Chip(
                label: Text(
                  item['inventory']['name'],
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.grey.shade200,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History - ${widget.productName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
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
                )
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) => _buildHistoryItem(_history[index]),
                ),
    );
  }
} 