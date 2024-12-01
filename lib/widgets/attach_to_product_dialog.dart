import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../services/supabase_database.dart';

class AttachToProductDialog extends StatefulWidget {
  final String partId;
  final String partName;

  const AttachToProductDialog({
    Key? key, 
    required this.partId,
    required this.partName,
  }) : super(key: key);

  @override
  _AttachToProductDialogState createState() => _AttachToProductDialogState();
}

class _AttachToProductDialogState extends State<AttachToProductDialog> {
  String? _selectedProductId;
  late Future<List<InventoryItem>> _productsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    _productsFuture = SupabaseDatabase.instance.getProducts();
  }

  Future<void> _attachToProduct() async {
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SupabaseDatabase.instance.addPartToProduct(
        _selectedProductId!,
        widget.partId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Part attached successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error attaching part: $e'),
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
    return AlertDialog(
      title: const Text('Select Product'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attaching part: ${widget.partName}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<InventoryItem>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Text('No products available');
                }

                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return RadioListTile<String>(
                        title: Text(product.name),
                        subtitle: Text(
                          'Category: ${product.category}\n'
                          'Serial: ${product.serialNumber}',
                        ),
                        value: product.id,
                        groupValue: _selectedProductId,
                        onChanged: (value) {
                          setState(() => _selectedProductId = value);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _attachToProduct,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Attach'),
        ),
      ],
    );
  }
} 