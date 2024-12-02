import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../models/cart_item.dart';
import '../services/supabase_database.dart';
import 'sale_receipt.dart';

class CheckoutSheet extends StatefulWidget {
  final List<CartItem> cart;
  final VoidCallback onSuccess;

  const CheckoutSheet({
    super.key,
    required this.cart,
    required this.onSuccess,
  });

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _transactionCodeController = TextEditingController();
  String _paymentMethod = 'Mobile Money';
  bool _isLoading = false;

  @override
  void dispose() {
    _transactionCodeController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _totalAmount =>
      widget.cart.fold(0, (sum, item) => sum + (item.item.sellingPrice * item.quantity));

  Future<void> _completeSale() async {
    if (widget.cart.isEmpty) return;

    if (_paymentMethod == 'Mobile Money' && _transactionCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the transaction code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final saleDate = DateTime.now();
      
      await SupabaseDatabase.instance.supabase.rpc('begin_transaction');

      final receiptData = {
        'total_amount': _totalAmount,
        'customer_name': _customerNameController.text.trim(),
        'customer_phone': _customerPhoneController.text.trim(),
        'payment_method': _paymentMethod,
        'transaction_code': _paymentMethod == 'Mobile Money' ? _transactionCodeController.text.trim() : null,
        'sale_date': saleDate.toIso8601String(),
        'notes': _notesController.text.trim(),
      };

      final receiptResponse = await SupabaseDatabase.instance.supabase
          .from('receipts')
          .insert(receiptData)
          .select()
          .single();

      final receiptId = receiptResponse['id'];
      final receiptNumber = receiptResponse['receipt_number'];

      for (final cartItem in widget.cart) {
        final sale = Sale(
          itemId: cartItem.item.id,
          itemName: cartItem.item.name,
          category: cartItem.item.category,
          quantitySold: cartItem.quantity,
          sellingPrice: cartItem.item.sellingPrice,
          totalPrice: cartItem.item.sellingPrice * cartItem.quantity,
          saleDate: saleDate,
          customerName: _customerNameController.text.trim(),
          customerPhone: _customerPhoneController.text.trim(),
          paymentMethod: _paymentMethod,
          transactionCode: _paymentMethod == 'Mobile Money' ? _transactionCodeController.text.trim() : null,
          notes: _notesController.text.trim(),
          receiptId: receiptId,
        );

        await SupabaseDatabase.instance.addSale(sale);
      }

      await SupabaseDatabase.instance.supabase.rpc('commit_transaction');

      if (mounted) {
        Navigator.pop(context);
        
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SaleReceipt(
            cart: widget.cart,
            customerName: _customerNameController.text.trim(),
            customerPhone: _customerPhoneController.text.trim(),
            paymentMethod: _paymentMethod,
            receiptNumber: receiptNumber,
            saleDate: saleDate,
          ),
        );

        widget.onSuccess();
      }
    } catch (e) {
      await SupabaseDatabase.instance.supabase.rpc('rollback_transaction');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing sale: $e'),
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _customerPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Phone (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Cash', 'Mobile Money', 'Card', 'Bank Transfer']
                      .map((method) => DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _paymentMethod = value;
                        if (value != 'Mobile Money') {
                          _transactionCodeController.clear();
                        }
                      });
                    }
                  },
                ),
                if (_paymentMethod == 'Mobile Money') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _transactionCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Transaction Code *',
                      border: OutlineInputBorder(),
                      helperText: 'Enter the M-PESA transaction code',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
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
                      'KSH ${_totalAmount.toStringAsFixed(2)}',
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _completeSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Complete Sale'),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 