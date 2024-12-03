import 'package:flutter/material.dart';
import 'dart:async';
import '../models/inventory_item.dart';
import '../services/supabase_database.dart';
import 'add_edit_item_screen.dart';
import 'product_details_screen.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

enum SortOption {
  nameAZ('Name (A-Z)'),
  nameZA('Name (Z-A)'),
  quantityHighLow('Quantity (High-Low)'),
  quantityLowHigh('Quantity (Low-High)'),
  recentlyUpdated('Recently Updated'),
  oldestFirst('Oldest First');

  const SortOption(this.label);
  final String label;
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<InventoryItem> _allItems = [];
  List<InventoryItem> _filteredItems = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _selectedCategory;
  Timer? _debounceTimer;
  String _sortBy = 'name';  // Default sort
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _checkAndLoadData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _filterItems(_searchController.text);
    });
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        query = query.toLowerCase();
        _filteredItems = _allItems.where((item) {
          return item.name.toLowerCase().contains(query) ||
                 item.serialNumber.toLowerCase().contains(query) ||
                 item.category.toLowerCase().contains(query);
        }).toList();
      }

      // Apply category filter if selected
      if (_selectedCategory != null && _selectedCategory != 'All') {
        _filteredItems = _filteredItems.where((item) => 
          item.category == _selectedCategory
        ).toList();
      }
    });
  }

  Future<void> _checkAndLoadData() async {
    try {
      setState(() => _isLoading = true);
      await _loadItems();
      await _loadCategories();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await SupabaseDatabase.instance.getCategories();
      setState(() {
        _categories = ['All', ...categories];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadItems() async {
    try {
      final items = await SupabaseDatabase.instance.getAllItems();
      setState(() {
        _allItems = items;
        _filteredItems = items;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sortItems() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _filteredItems.sort((a, b) => _sortAscending
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name));
          break;
        case 'quantity':
          _filteredItems.sort((a, b) => _sortAscending
              ? a.quantity.compareTo(b.quantity)
              : b.quantity.compareTo(a.quantity));
          break;
        case 'updated':
          _filteredItems.sort((a, b) => _sortAscending
              ? a.updatedAt.compareTo(b.updatedAt)
              : b.updatedAt.compareTo(a.updatedAt));
          break;
      }
    });
  }

  void _handleSort(SortOption option) {
    setState(() {
      switch (option) {
        case SortOption.nameAZ:
          _sortBy = 'name';
          _sortAscending = true;
          break;
        case SortOption.nameZA:
          _sortBy = 'name';
          _sortAscending = false;
          break;
        case SortOption.quantityHighLow:
          _sortBy = 'quantity';
          _sortAscending = false;
          break;
        case SortOption.quantityLowHigh:
          _sortBy = 'quantity';
          _sortAscending = true;
          break;
        case SortOption.recentlyUpdated:
          _sortBy = 'updated';
          _sortAscending = false;
          break;
        case SortOption.oldestFirst:
          _sortBy = 'updated';
          _sortAscending = true;
          break;
      }
      _sortItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: _handleSort,
            itemBuilder: (BuildContext context) {
              return SortOption.values.map((SortOption option) {
                return PopupMenuItem<SortOption>(
                  value: option,
                  child: Row(
                    children: [
                      Icon(
                        _getSortIcon(option),
                        color: _sortBy == _getSortType(option) &&
                                _sortAscending == _isAscending(option)
                            ? Theme.of(context).primaryColor
                            : null,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(option.label),
                      if (_sortBy == _getSortType(option) &&
                          _sortAscending == _isAscending(option))
                        const Spacer()
                      else
                        const SizedBox.shrink(),
                      if (_sortBy == _getSortType(option) &&
                          _sortAscending == _isAscending(option))
                        Icon(
                          Icons.check,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAndLoadData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterItems('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_categories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: FilterChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = selected ? category : null;
                                  _filterItems(_searchController.text);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadItems,
                    child: _filteredItems.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isEmpty
                                  ? 'No items found'
                                  : 'No results found for "${_searchController.text}"',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              return _buildItemTile(item);
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'inventory_fab',
        onPressed: _addNewItem,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Future<void> _handleMenuAction(String action, InventoryItem item) async {
    switch (action) {
      case 'view':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(productId: item.id),
          ),
        );
        break;
      case 'edit':
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditItemScreen(item: item),
          ),
        );
        if (result == true && mounted) {
          await _loadItems();
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Delete Product'),
            content: Text('Are you sure you want to delete "${item.name}"?'),
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

        if (confirm == true && mounted) {
          try {
            await SupabaseDatabase.instance.deleteItem(item.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product deleted successfully')),
            );
            _loadItems();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting product: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
        break;
    }
  }

  Future<void> _addNewItem() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditItemScreen(),
      ),
    );
    if (result == true && mounted) {
      await _loadItems();
    }
  }

  Widget _buildItemTile(InventoryItem item) {
    return FutureBuilder<List<InventoryItem>>(
      future: item.category != 'Parts' 
          ? SupabaseDatabase.instance.getProductParts(item.id)
          : Future.value([]),
      builder: (context, snapshot) {
        final hasParts = snapshot.hasData && snapshot.data!.isNotEmpty;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            leading: Stack(
              children: [
                Icon(
                  item.category == 'Parts' ? Icons.build : Icons.inventory_2,
                  color: Colors.blue,
                ),
                if (hasParts)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.build,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(child: Text(item.name)),
                if (item.category == 'Parts')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: const Text(
                      'Part',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  )
                else if (hasParts)
                  Tooltip(
                    message: 'Has attached parts - Cannot be deleted',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Text(
                        'Has Parts',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${item.category}'),
                Text('Quantity: ${item.quantity}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (action) => _handleMenuAction(action, item),
              itemBuilder: (context) {
                return [
                  if (item.category != 'Parts')
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  if (!hasParts)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ];
              },
              tooltip: hasParts ? 'Limited options - Has attached parts' : 'More options',
              icon: const Icon(Icons.more_vert),
            ),
            onTap: () {
              if (item.category != 'Parts') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsScreen(productId: item.id),
                  ),
                ).then((_) {
                  // Refresh the list when returning from product details
                  setState(() {
                    _loadItems();
                  });
                });
              }
            },
          ),
        );
      },
    );
  }

  String _getSortType(SortOption option) {
    switch (option) {
      case SortOption.nameAZ:
      case SortOption.nameZA:
        return 'name';
      case SortOption.quantityHighLow:
      case SortOption.quantityLowHigh:
        return 'quantity';
      case SortOption.recentlyUpdated:
      case SortOption.oldestFirst:
        return 'updated';
    }
  }

  bool _isAscending(SortOption option) {
    switch (option) {
      case SortOption.nameAZ:
      case SortOption.quantityLowHigh:
      case SortOption.oldestFirst:
        return true;
      case SortOption.nameZA:
      case SortOption.quantityHighLow:
      case SortOption.recentlyUpdated:
        return false;
    }
  }

  IconData _getSortIcon(SortOption option) {
    switch (option) {
      case SortOption.nameAZ:
      case SortOption.nameZA:
        return Icons.sort_by_alpha;
      case SortOption.quantityHighLow:
      case SortOption.quantityLowHigh:
        return Icons.sort;
      case SortOption.recentlyUpdated:
      case SortOption.oldestFirst:
        return Icons.update;
    }
  }
} 