class TopSellingProduct {
  final String itemId;
  final String itemName;
  final String category;
  final int quantitySold;
  final double totalRevenue;
  final double averagePrice;
  final double profitMargin;

  TopSellingProduct.fromJson(Map<String, dynamic> json)
      : itemId = json['item_id'],
        itemName = json['item_name'],
        category = json['category'],
        quantitySold = json['quantity_sold'],
        totalRevenue = (json['total_revenue'] as num).toDouble(),
        averagePrice = (json['average_price'] as num).toDouble(),
        profitMargin = (json['profit_margin'] as num).toDouble();
}

class CategorySalesPerformance {
  final String category;
  final int totalItemsSold;
  final double totalRevenue;
  final double averageItemPrice;
  final int uniqueProducts;
  final double categoryProfit;

  CategorySalesPerformance.fromJson(Map<String, dynamic> json)
      : category = json['category'],
        totalItemsSold = json['total_items_sold'],
        totalRevenue = (json['total_revenue'] as num).toDouble(),
        averageItemPrice = (json['average_item_price'] as num).toDouble(),
        uniqueProducts = json['unique_products'],
        categoryProfit = (json['category_profit'] as num).toDouble();
}

class PartsSalesAnalysis {
  final String partId;
  final String partName;
  final int quantitySold;
  final double totalRevenue;
  final double averagePrice;
  final int currentStock;
  final bool reorderSuggestion;

  PartsSalesAnalysis.fromJson(Map<String, dynamic> json)
      : partId = json['part_id'],
        partName = json['part_name'],
        quantitySold = json['quantity_sold'],
        totalRevenue = (json['total_revenue'] as num).toDouble(),
        averagePrice = (json['average_price'] as num).toDouble(),
        currentStock = json['current_stock'],
        reorderSuggestion = json['reorder_suggestion'];
}

class SalesTrendAnalysis {
  final DateTime saleDate;
  final double dailyRevenue;
  final int itemsSold;
  final int transactionCount;
  final double averageTransactionValue;
  final int uniqueCustomers;

  SalesTrendAnalysis.fromJson(Map<String, dynamic> json)
      : saleDate = DateTime.parse(json['sale_date']),
        dailyRevenue = (json['daily_revenue'] as num).toDouble(),
        itemsSold = json['items_sold'],
        transactionCount = json['transaction_count'],
        averageTransactionValue = (json['average_transaction_value'] as num).toDouble(),
        uniqueCustomers = json['unique_customers'];
}

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

  ProductPerformanceMetrics.fromJson(Map<String, dynamic> json)
      : itemId = json['item_id'],
        itemName = json['item_name'],
        category = json['category'],
        totalRevenue = (json['total_revenue'] as num).toDouble(),
        quantitySold = json['quantity_sold'],
        profitMargin = (json['profit_margin'] as num).toDouble(),
        revenueShare = (json['revenue_share'] as num).toDouble(),
        stockTurnover = (json['stock_turnover'] as num).toDouble(),
        daysToStockout = json['days_to_stockout'];
} 