import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sale.dart';
import '../models/inventory_item.dart';
import '../services/supabase_database.dart';
import 'package:intl/intl.dart';

class AddSaleScreen extends StatefulWidget {
  final InventoryItem? selectedItem;

  const AddSaleScreen({super.key, this.selectedItem});

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _notesController;
  
  InventoryItem? _selectedItem;
  String _paymentMethod = 'Cash';
  DateTime _saleDate = DateTime.now();
  bool _isLoading = false;
  double _totalPrice = 0.0;

  final List<String> _paymentMethods = ['Cash', 'Card', 'Mobile Money', 'Bank Transfer'];

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.selectedItem;
    _quantityController = TextEditingController(text: '1');
    _customerNameController = TextEditingController();
    _customerPhoneController = TextEditingController();
    _notesController = TextEditingController();
    _calculateTotal();
  }

  void _calculateTotal() {
    if (_selectedItem != null) {
      final quantity = int.tryParse(_quantityController.text) ?? 0;
      setState(() {
        _totalPrice = _selectedItem!.sellingPrice * quantity;
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _saleDate) {
      setState(() {
        _saleDate = picked;
      });
    }
  }

  Future<void> _selectItem() async {
    // Show dialog to choose between Product or Part
    final itemType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Item Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.inventory_2),
                title: const Text('Product'),
                onTap: () => Navigator.pop(context, 'product'),
              ),
              ListTile(
                leading: const Icon(Icons.build),
                title: const Text('Part'),
                onTap: () => Navigator.pop(context, 'part'),
              ),
            ],
          ),
        );
      },
    );

    if (itemType == null) return;

    try {
      List<InventoryItem> items;
      if (itemType == 'product') {
        items = await SupabaseDatabase.instance.getProducts();
      } else {
        items = await SupabaseDatabase.instance.getUnattachedProducts();
      }

      if (!mounted) return;

      final selectedItem = await showDialog<InventoryItem>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select ${itemType == 'product' ? 'Product' : 'Part'}'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: Icon(
                      itemType == 'product' ? Icons.inventory_2 : Icons.build,
                      color: Colors.blue,
                    ),
                    title: Text(item.name),
                    subtitle: Text(
                      'Available: ${item.quantity} | Price: KSH ${item.sellingPrice}',
                    ),
                    onTap: () => Navigator.pop(context, item),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (selectedItem != null) {
        setState(() {
          _selectedItem = selectedItem;
          _calculateTotal();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading items: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate() || _selectedItem == null) return;

    setState(() => _isLoading = true);

    try {
      final quantity = int.parse(_quantityController.text);
      
      if (quantity > _selectedItem!.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough items in stock'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final newSale = Sale(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        itemId: _selectedItem!.id,
        itemName: _selectedItem!.name,
        category: _selectedItem!.category,
        quantitySold: quantity,
        sellingPrice: _selectedItem!.sellingPrice,
        totalPrice: _totalPrice,
        saleDate: _saleDate,
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim(),
      );

      await SupabaseDatabase.instance.addSale(newSale);
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving sale: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Sale'),
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
                    Row(
                      children: [
                        Expanded(
                          child: _selectedItem != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _selectedItem!.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _selectedItem!.category == 'Parts'
                                                ? Colors.blue.shade100
                                                : Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _selectedItem!.category == 'Parts'
                                                  ? Colors.blue
                                                  : Colors.green,
                                            ),
                                          ),
                                          child: Text(
                                            _selectedItem!.category == 'Parts'
                                                ? 'Part'
                                                : 'Product',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _selectedItem!.category == 'Parts'
                                                  ? Colors.blue
                                                  : Colors.green,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Available: ${_selectedItem!.quantity}',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                )
                              : const Text('No item selected'),
                        ),
                        TextButton(
                          onPressed: _selectItem,
                          child: const Text('Select Item'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter quantity';
                        }
                        final quantity = int.tryParse(value);
                        if (quantity == null || quantity <= 0) {
                          return 'Please enter a valid quantity';
                        }
                        if (_selectedItem != null && quantity > _selectedItem!.quantity) {
                          return 'Not enough items in stock';
                        }
                        return null;
                      },
                      onChanged: (value) => _calculateTotal(),
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
                    ListTile(
                      title: const Text('Sale Date'),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(_saleDate)),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(),
                      ),
                      items: _paymentMethods.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _paymentMethod = value!);
                      },
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
                      'Customer Details (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _customerPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Phone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'KSH ${_totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Complete Sale'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 