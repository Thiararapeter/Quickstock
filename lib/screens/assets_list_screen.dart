import 'package:flutter/material.dart';
import 'dart:async';
import '../models/asset.dart';
import '../services/supabase_database.dart';
import 'add_edit_asset_screen.dart';
import 'package:intl/intl.dart';
import 'asset_details_screen.dart';

enum SortOption {
  nameAZ('Name (A-Z)'),
  nameZA('Name (Z-A)'),
  valueHighLow('Value (High-Low)'),
  valueLowHigh('Value (Low-High)'),
  recentlyUpdated('Recently Updated'),
  oldestFirst('Oldest First');

  const SortOption(this.label);
  final String label;
}

class AssetsListScreen extends StatefulWidget {
  const AssetsListScreen({super.key});

  @override
  State<AssetsListScreen> createState() => _AssetsListScreenState();
}

class _AssetsListScreenState extends State<AssetsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Asset> _allAssets = [];
  List<Asset> _filteredAssets = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  final _currencyFormat = NumberFormat.currency(symbol: 'KSH ', decimalDigits: 2);
  String _sortBy = 'name';  // Default sort
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadAssets();
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
      _filterAssets(_searchController.text);
    });
  }

  void _filterAssets(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAssets = _allAssets;
      } else {
        query = query.toLowerCase();
        _filteredAssets = _allAssets.where((asset) {
          return asset.name.toLowerCase().contains(query) ||
                 asset.serialNumber.toLowerCase().contains(query) ||
                 asset.type.toLowerCase().contains(query) ||
                 asset.location.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    try {
      final assets = await SupabaseDatabase.instance.getAssets();
      setState(() {
        _allAssets = assets;
        _filteredAssets = assets;  // Initialize filtered list with all assets
      });
    } catch (e) {
      _showSnackBar('Error loading assets: $e', true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, bool isError) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(String action, Asset asset) async {
    switch (action) {
      case 'edit':
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditAssetScreen(asset: asset),
          ),
        );
        if (result == true && mounted) {
          _loadAssets();
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Delete Asset'),
            content: Text('Are you sure you want to delete "${asset.name}"?'),
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
            await SupabaseDatabase.instance.deleteAsset(asset.id);
            _showSnackBar('Asset deleted successfully', false);
            _loadAssets();
          } catch (e) {
            _showSnackBar('Error deleting asset: $e', true);
          }
        }
        break;
    }
  }

  Future<void> _addEditAsset([Asset? asset]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAssetScreen(asset: asset),
      ),
    );

    if (result == true && mounted) {
      _showSnackBar(
        asset == null ? 'Asset added successfully' : 'Asset updated successfully',
        false
      );
      _loadAssets();
    }
  }

  Future<void> _reloadScreen() async {
    setState(() => _isLoading = true);
    await _loadAssets();
    setState(() => _isLoading = false);
  }

  void _sortAssets() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _filteredAssets.sort((a, b) => _sortAscending
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name));
          break;
        case 'value':
          _filteredAssets.sort((a, b) => _sortAscending
              ? a.purchasePrice.compareTo(b.purchasePrice)
              : b.purchasePrice.compareTo(a.purchasePrice));
          break;
        case 'updated':
          _filteredAssets.sort((a, b) => _sortAscending
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
        case SortOption.valueHighLow:
          _sortBy = 'value';
          _sortAscending = false;
          break;
        case SortOption.valueLowHigh:
          _sortBy = 'value';
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
      _sortAssets();
    });
  }

  String _getSortType(SortOption option) {
    switch (option) {
      case SortOption.nameAZ:
      case SortOption.nameZA:
        return 'name';
      case SortOption.valueHighLow:
      case SortOption.valueLowHigh:
        return 'value';
      case SortOption.recentlyUpdated:
      case SortOption.oldestFirst:
        return 'updated';
    }
  }

  bool _isAscending(SortOption option) {
    switch (option) {
      case SortOption.nameAZ:
      case SortOption.valueLowHigh:
      case SortOption.oldestFirst:
        return true;
      case SortOption.nameZA:
      case SortOption.valueHighLow:
      case SortOption.recentlyUpdated:
        return false;
    }
  }

  IconData _getSortIcon(SortOption option) {
    switch (option) {
      case SortOption.nameAZ:
      case SortOption.nameZA:
        return Icons.sort_by_alpha;
      case SortOption.valueHighLow:
      case SortOption.valueLowHigh:
        return Icons.attach_money;
      case SortOption.recentlyUpdated:
      case SortOption.oldestFirst:
        return Icons.update;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assets'),
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
            onPressed: _reloadScreen,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search assets...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAssets.isEmpty
                    ? const Center(child: Text('No assets found'))
                    : ListView.builder(
                        itemCount: _filteredAssets.length,
                        itemBuilder: (context, index) {
                          final asset = _filteredAssets[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: Icon(
                                asset.type == 'Tool' ? Icons.handyman 
                                : Icons.precision_manufacturing,
                                color: Colors.blue,
                              ),
                              title: Text(asset.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Type: ${asset.type}'),
                                  Text('Location: ${asset.location}'),
                                  Text('Value: ${_currencyFormat.format(asset.purchasePrice)}'),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) => _handleMenuAction(action, asset),
                                itemBuilder: (BuildContext context) => [
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
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AssetDetailsScreen(assetId: asset.id),
                                  ),
                                ).then((_) {
                                  // Refresh the list when returning from details
                                  setState(() {
                                    _loadAssets();
                                  });
                                });
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditAssetScreen(),
            ),
          );
          if (result == true && mounted) {
            _loadAssets();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Asset'),
      ),
    );
  }
} 