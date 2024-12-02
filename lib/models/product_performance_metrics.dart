class ProductPerformanceMetrics {
  final String itemId;
  final String itemName;
  final String category;
  final double totalRevenue;
  final int quantitySold;
  final double profitMargin;
  final double revenueShare;
  final double stockTurnover;
  final int? daysToStockout;
  final int currentStock;

  ProductPerformanceMetrics({
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.totalRevenue,
    required this.quantitySold,
    required this.profitMargin,
    required this.revenueShare,
    required this.stockTurnover,
    this.daysToStockout,
    required this.currentStock,
  });

  factory ProductPerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return ProductPerformanceMetrics(
      itemId: json['item_id'] as String,
      itemName: json['item_name'] as String,
      category: json['category'] as String,
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      quantitySold: json['quantity_sold'] as int,
      profitMargin: (json['profit_margin'] as num).toDouble(),
      revenueShare: (json['revenue_share'] as num).toDouble(),
      stockTurnover: (json['stock_turnover'] as num).toDouble(),
      daysToStockout: json['days_to_stockout'] as int?,
      currentStock: json['current_stock'] as int,
    );
  }
} 