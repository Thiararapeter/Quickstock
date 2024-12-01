import 'package:flutter/material.dart';
import '../services/supabase_database.dart';
import '../models/inventory_item.dart';
import '../models/asset.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  bool _mounted = true;
  List<InventoryItem> _items = [];
  List<Asset> _assets = [];
  List<Expense> _expenses = [];
  final _currencyFormat = NumberFormat.currency(
    symbol: 'KSH ',
    decimalDigits: 2,
  );

  // Inventory metrics
  Map<String, int> _itemsByCategory = {};
  int get _totalItems => _items.length;
  int get _lowStockItems => _items.where((item) => item.quantity < 5).length;
  double get _inventoryValue => _items.fold(
        0,
        (sum, item) => sum + (item.sellingPrice * item.quantity),
      );

  // Asset metrics
  double get _totalAssetValue => _assets.fold(
        0,
        (sum, asset) => sum + asset.purchasePrice,
      );
  Map<String, int> get _assetsByType => _assets.fold(
        {},
        (map, asset) {
          map[asset.type] = (map[asset.type] ?? 0) + 1;
          return map;
        },
      );

  // Expense metrics
  double get _totalExpenses => _expenses.fold(
        0,
        (sum, expense) => sum + expense.amount,
      );
  Map<String, double> get _expensesByCategory => _expenses.fold(
        {},
        (map, expense) {
          map[expense.category] = (map[expense.category] ?? 0) + expense.amount;
          return map;
        },
      );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!_mounted) return;
    setState(() => _isLoading = true);

    try {
      final futures = await Future.wait([
        SupabaseDatabase.instance.getAllItems(),
        SupabaseDatabase.instance.getAssets(),
        SupabaseDatabase.instance.getExpenses(),
      ]);

      if (!_mounted) return;

      setState(() {
        _items = futures[0] as List<InventoryItem>;
        _assets = futures[1] as List<Asset>;
        _expenses = futures[2] as List<Expense>;
        
        _itemsByCategory = _items.fold({}, (map, item) {
          map[item.category] = (map[item.category] ?? 0) + 1;
          return map;
        });
      });
    } catch (e) {
      if (!_mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      if (_mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Overview'),
                    _buildOverviewCards(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Inventory Status'),
                    _buildInventoryStatus(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Asset Distribution'),
                    _buildAssetDistribution(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Expense Summary'),
                    _buildExpenseSummary(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildOverviewCards() {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Total Inventory Value',
          _currencyFormat.format(_inventoryValue),
          Icons.inventory,
          Colors.blue,
        ),
        _buildMetricCard(
          'Total Asset Value',
          _currencyFormat.format(_totalAssetValue),
          Icons.precision_manufacturing,
          Colors.green,
        ),
        _buildMetricCard(
          'Total Expenses',
          _currencyFormat.format(_totalExpenses),
          Icons.account_balance_wallet,
          Colors.orange,
        ),
        _buildMetricCard(
          'Low Stock Items',
          _lowStockItems.toString(),
          Icons.warning,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var entry in _itemsByCategory.entries.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      '${entry.value} items',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            if (_itemsByCategory.length > 5)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/inventory');
                  },
                  child: const Text('View All'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetDistribution() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var entry in _assetsByType.entries.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      '${entry.value} assets',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            if (_assetsByType.length > 5)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/assets');
                  },
                  child: const Text('View All'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var entry in _expensesByCategory.entries.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      _currencyFormat.format(entry.value),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            if (_expensesByCategory.length > 5)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/expenses');
                  },
                  child: const Text('View All'),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 