import 'package:flutter/material.dart';
import '../../models/asset.dart';
import '../../services/supabase_database.dart';
import 'base_report_screen.dart';
import 'package:collection/collection.dart';

class AssetReportScreen extends BaseReportScreen {
  const AssetReportScreen({super.key}) : super(title: 'Asset Report');

  @override
  State<AssetReportScreen> createState() => _AssetReportScreenState();
}

class _AssetReportScreenState extends BaseReportScreenState<AssetReportScreen> {
  List<Asset> _assets = [];

  @override
  Future<void> loadReportData() async {
    final assets = await SupabaseDatabase.instance.getAssets();
    setState(() {
      _assets = assets;
    });
  }

  @override
  Widget buildReportContent() {
    if (_assets.isEmpty) {
      return const Center(
        child: Text('No assets data available'),
      );
    }

    final totalValue = _assets.fold<double>(
      0,
      (sum, asset) => sum + asset.purchasePrice,
    );

    final assetsByType = groupBy(_assets, (Asset asset) => asset.type);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildSummaryCard(
          title: 'Asset Summary',
          rows: [
            MapEntry('Total Asset Value', currencyFormat.format(totalValue)),
            MapEntry('Total Assets', _assets.length.toString()),
            MapEntry(
              'Average Asset Value',
              currencyFormat.format(_assets.isEmpty ? 0 : totalValue / _assets.length),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        buildSummaryCard(
          title: 'Assets by Type',
          rows: assetsByType.entries.map((entry) {
            final typeTotal = entry.value.fold<double>(
              0,
              (sum, asset) => sum + asset.purchasePrice,
            );
            return MapEntry(
              '${entry.key} (${entry.value.length})',
              currencyFormat.format(typeTotal),
            );
          }).toList(),
        ),
      ],
    );
  }
} 