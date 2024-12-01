import 'package:flutter/material.dart';
import '../models/inventory_item.dart';

class ItemSelectionDialog extends StatefulWidget {
  final List<InventoryItem> items;
  final String itemType;

  const ItemSelectionDialog({
    super.key,
    required this.items,
    required this.itemType,
  });

  @override
  State<ItemSelectionDialog> createState() => _ItemSelectionDialogState();
}

class _ItemSelectionDialogState extends State<ItemSelectionDialog> {
  late List<InventoryItem> _filteredItems;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.serialNumber.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  widget.itemType == 'product' 
                      ? Icons.inventory_2 
                      : Icons.build,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select ${widget.itemType == 'product' ? 'Product' : 'Part'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or serial number',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No ${widget.itemType}s found',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              child: Icon(
                                widget.itemType == 'product' 
                                    ? Icons.inventory_2 
                                    : Icons.build,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.serialNumber.isNotEmpty)
                                  Text('S/N: ${item.serialNumber}'),
                                Text(
                                  'Available: ${item.quantity} | Price: KSH ${item.sellingPrice}',
                                  style: TextStyle(
                                    color: item.quantity > 0 
                                        ? Colors.green 
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            enabled: item.quantity > 0,
                            onTap: item.quantity > 0
                                ? () => Navigator.pop(context, item)
                                : null,
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
} 