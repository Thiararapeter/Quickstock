class SalesReport {
  final DateTime date;
  final double totalSales;
  final int totalItemsSold;
  final Map<String, double> paymentMethodTotals;
  final List<ProductSalesDetail> topProducts;

  SalesReport({
    required this.date,
    this.totalSales = 0.0,
    this.totalItemsSold = 0,
    Map<String, double>? paymentMethodTotals,
    List<ProductSalesDetail>? topProducts,
  }) : 
    this.paymentMethodTotals = paymentMethodTotals ?? {},
    this.topProducts = topProducts ?? [];

  factory SalesReport.fromJson(Map<String, dynamic> json) {
    return SalesReport(
      date: DateTime.parse(json['sale_date'] ?? DateTime.now().toIso8601String()),
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalItemsSold: (json['total_items_sold'] as num?)?.toInt() ?? 0,
      paymentMethodTotals: (json['payment_method_totals'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ?? {},
      topProducts: (json['top_products'] as List?)
          ?.map((product) => ProductSalesDetail.fromJson(product))
          .toList() ?? [],
    );
  }
}

class ProductSalesDetail {
  final String itemId;
  final String itemName;
  final String category;
  final int quantitySold;
  final double totalSales;
  final double averagePrice;

  ProductSalesDetail({
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.quantitySold,
    required this.totalSales,
    required this.averagePrice,
  });

  factory ProductSalesDetail.fromJson(Map<String, dynamic> json) {
    return ProductSalesDetail(
      itemId: json['item_id'],
      itemName: json['item_name'],
      category: json['category'],
      quantitySold: json['total_quantity_sold'],
      totalSales: json['total_sales'].toDouble(),
      averagePrice: json['average_price'].toDouble(),
    );
  }
} 