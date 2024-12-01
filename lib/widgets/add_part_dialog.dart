import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../services/supabase_database.dart';

class AddPartDialog extends StatefulWidget {
  const AddPartDialog({Key? key}) : super(key: key);

  @override
  State<AddPartDialog> createState() => _AddPartDialogState();
}

class _AddPartDialogState extends State<AddPartDialog> {
  String? _selectedPartId;
  String _partsCategory = 'Component'; // Default category

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Part'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FutureBuilder<List<InventoryItem>>(
            future: SupabaseDatabase.instance.getUnattachedProducts(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final parts = snapshot.data!;
                return DropdownButtonFormField<String>(
                  value: _selectedPartId,
                  hint: const Text('Select Part'),
                  items: parts.map((part) {
                    return DropdownMenuItem(
                      value: part.id,
                      child: Text(part.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPartId = value);
                  },
                );
              }
              return const CircularProgressIndicator();
            },
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Parts Category',
              hintText: 'e.g., Component, Accessory, etc.',
            ),
            onChanged: (value) => _partsCategory = value,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _selectedPartId == null
              ? null
              : () => Navigator.pop(context, {
                    'partId': _selectedPartId,
                    'partsCategory': _partsCategory,
                  }),
          child: const Text('Add'),
        ),
      ],
    );
  }
} 