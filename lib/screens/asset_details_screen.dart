import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/supabase_database.dart';
import 'package:intl/intl.dart';
import 'add_edit_asset_screen.dart';

class AssetDetailsScreen extends StatefulWidget {
  final String assetId;

  const AssetDetailsScreen({Key? key, required this.assetId}) : super(key: key);

  @override
  State<AssetDetailsScreen> createState() => _AssetDetailsScreenState();
}

class _AssetDetailsScreenState extends State<AssetDetailsScreen> {
  late Future<Asset?> _assetFuture;
  final _currencyFormat = NumberFormat.currency(symbol: 'KSH ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _assetFuture = SupabaseDatabase.instance.getAsset(widget.assetId);
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

  Future<void> _deleteAsset(Asset asset) async {
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
        Navigator.pop(context, true); // Return to previous screen
      } catch (e) {
        _showSnackBar('Error deleting asset: $e', true);
      }
    }
  }

  Future<void> _editAsset(Asset asset) async {
    try {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditAssetScreen(asset: asset),
        ),
      );

      if (result == true && mounted) {
        _showSnackBar('Asset updated successfully', false);
        setState(() {
          _loadData(); // Reload the asset data
        });
      }
    } catch (e) {
      _showSnackBar('Error updating asset: $e', true);
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Details'),
        actions: [
          FutureBuilder<Asset?>(
            future: _assetFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit Asset',
                      onPressed: () => _editAsset(snapshot.data!),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete Asset',
                      onPressed: () => _deleteAsset(snapshot.data!),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<Asset?>(
        future: _assetFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading asset: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _loadData()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final asset = snapshot.data;
          if (asset == null) {
            return const Center(
              child: Text('Asset not found'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _loadData()),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              asset.type == 'Tool' ? Icons.handyman 
                              : Icons.precision_manufacturing,
                              color: Colors.blue,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    asset.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    asset.type,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        _buildInfoRow('Serial Number', asset.serialNumber),
                        _buildInfoRow('Location', asset.location),
                        _buildInfoRow('Condition', asset.condition),
                        _buildInfoRow(
                          'Purchase Price', 
                          _currencyFormat.format(asset.purchasePrice)
                        ),
                        _buildInfoRow(
                          'Purchase Date',
                          DateFormat('MMM d, y').format(asset.purchaseDate),
                        ),
                        const Divider(height: 32),
                        _buildInfoRow(
                          'Date Added',
                          DateFormat('MMM d, y').format(asset.dateAdded),
                        ),
                        _buildInfoRow(
                          'Last Updated',
                          DateFormat('MMM d, y HH:mm').format(asset.updatedAt),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 