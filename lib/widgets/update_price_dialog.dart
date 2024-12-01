import 'package:flutter/material.dart';

class UpdatePriceDialog extends StatefulWidget {
  const UpdatePriceDialog({Key? key}) : super(key: key);

  @override
  _UpdatePriceDialogState createState() => _UpdatePriceDialogState();
}

class _UpdatePriceDialogState extends State<UpdatePriceDialog> {
  final _priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Product Price'),
      content: TextField(
        controller: _priceController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'New Price',
          prefixText: '\$',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final price = double.tryParse(_priceController.text);
            if (price != null) {
              Navigator.pop(context, price);
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
} 