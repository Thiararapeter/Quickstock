import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sales_report.dart';
import '../models/product_performance_metrics.dart';
import '../models/expense_report.dart';

class ReportsService {
  final SupabaseClient _supabase;

  ReportsService(this._supabase);

  Future<SalesReport> getDailySalesReport(DateTime date) async {
    try {
      // Format date to match PostgreSQL date format
      final formattedDate = date.toIso8601String().split('T')[0];
      
      final response = await _supabase
          .rpc('get_daily_sales_report', params: {
            'report_date': formattedDate,
          });

      if (response == null) {
        throw Exception('No data returned from the database');
      }

      // Initialize default values
      double totalSales = 0;
      int totalItemsSold = 0;
      Map<String, double> paymentMethodTotals = {};

      // Process the response which should be a List
      if (response is List) {
        for (var row in response) {
          if (row['total_sales'] != null) {
            totalSales += (row['total_sales'] as num).toDouble();
          }
          if (row['total_items_sold'] != null) {
            totalItemsSold += (row['total_items_sold'] as num).toInt();
          }
          if (row['payment_method'] != null && row['payment_method_total'] != null) {
            paymentMethodTotals[row['payment_method']] = 
                (row['payment_method_total'] as num).toDouble();
          }
        }
      }

      // Get product sales for the same date
      final productSalesResponse = await _supabase
          .rpc('get_product_sales_report', params: {
            'start_date': formattedDate,
            'end_date': formattedDate,
          });

      List<ProductSalesDetail> topProducts = [];
      if (productSalesResponse is List) {
        topProducts = productSalesResponse.map((product) {
          return ProductSalesDetail(
            itemId: product['item_id'] ?? '',
            itemName: product['item_name'] ?? '',
            category: product['category'] ?? '',
            quantitySold: (product['total_quantity_sold'] as num?)?.toInt() ?? 0,
            totalSales: (product['total_sales'] as num?)?.toDouble() ?? 0.0,
            averagePrice: (product['average_price'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();
      }

      return SalesReport(
        date: date,
        totalSales: totalSales,
        totalItemsSold: totalItemsSold,
        paymentMethodTotals: paymentMethodTotals,
        topProducts: topProducts,
      );
    } catch (e) {
      print('Error in getDailySalesReport: $e'); // Add this for debugging
      throw Exception('Failed to fetch daily sales report: $e');
    }
  }

  Future<List<SalesReport>> getDateRangeSalesReport(
      DateTime startDate, DateTime endDate) async {
    try {
      final response = await _supabase
          .rpc('get_sales_report_by_date_range', params: {
            'start_date': startDate.toIso8601String().split('T')[0],
            'end_date': endDate.toIso8601String().split('T')[0],
          });

      if (response == null) {
        return [];
      }

      // Group the response by date
      Map<String, List<dynamic>> salesByDate = {};
      if (response is List) {
        for (var row in response) {
          String date = row['sale_date'] ?? '';
          if (date.isNotEmpty) {
            salesByDate.putIfAbsent(date, () => []).add(row);
          }
        }
      }

      List<SalesReport> reports = [];
      for (var entry in salesByDate.entries) {
        double totalSales = 0;
        int totalItemsSold = 0;
        Map<String, double> paymentMethodTotals = {};

        for (var row in entry.value) {
          totalSales += (row['total_sales'] as num?)?.toDouble() ?? 0.0;
          totalItemsSold += (row['total_items_sold'] as num?)?.toInt() ?? 0;
          if (row['payment_method'] != null) {
            paymentMethodTotals[row['payment_method']] = 
                (row['payment_method_total'] as num?)?.toDouble() ?? 0.0;
          }
        }

        reports.add(SalesReport(
          date: DateTime.parse(entry.key),
          totalSales: totalSales,
          totalItemsSold: totalItemsSold,
          paymentMethodTotals: paymentMethodTotals,
          topProducts: [], // You can fetch product details if needed
        ));
      }

      return reports;
    } catch (e) {
      print('Error in getDateRangeSalesReport: $e'); // Add this for debugging
      throw Exception('Failed to fetch date range sales report: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startDateStr = startDate.toIso8601String();
      final endDateStr = endDate.toIso8601String();

      final response = await _supabase
          .rpc('get_top_selling_products', params: {
            'start_date': startDateStr,
            'end_date': endDateStr,
          });

      if (response == null) {
        throw Exception('No data returned from the database');
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load top selling products: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCategorySalesPerformance(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startDateStr = startDate.toIso8601String();
      final endDateStr = endDate.toIso8601String();

      final response = await _supabase
          .rpc('get_category_sales_performance', params: {
            'start_date': startDateStr,
            'end_date': endDateStr,
          });

      if (response == null) {
        throw Exception('No data returned from the database');
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load category sales performance: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPartsSalesAnalysis(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await _supabase.rpc(
      'get_parts_sales_analysis',
      params: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      },
    );
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getSalesTrendAnalysis(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await _supabase.rpc(
      'get_sales_trend_analysis',
      params: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      },
    );
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<ProductPerformanceMetrics>> getProductPerformanceMetrics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_product_performance_metrics',
        params: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );

      if (response == null) {
        throw Exception('No data returned from the database');
      }

      return (response as List)
          .map((json) => ProductPerformanceMetrics.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load product performance metrics: $e');
    }
  }

  Future<List<ExpenseReport>> getExpenseReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_expense_report',
        params: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );

      if (response == null) {
        throw Exception('No data returned from the database');
      }

      return (response as List)
          .map((json) => ExpenseReport.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load expense report: $e');
    }
  }
} 