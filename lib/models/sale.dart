import 'package:intl/intl.dart';

class Sale {
  final String id;
  final String itemId;
  final String itemName;
  final String category;
  final int quantitySold;
  final double sellingPrice;
  final double totalPrice;
  final DateTime saleDate;
  final String? customerName;
  final String? customerPhone;
  final String paymentMethod;
  final String? notes;

  Sale({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.quantitySold,
    required this.sellingPrice,
    required this.totalPrice,
    required this.saleDate,
    this.customerName,
    this.customerPhone,
    this.paymentMethod = 'Cash',
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'item_name': itemName,
      'category': category,
      'quantity_sold': quantitySold,
      'selling_price': sellingPrice,
      'total_price': totalPrice,
      'sale_date': saleDate.toIso8601String(),
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'payment_method': paymentMethod,
      'notes': notes,
    };
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      itemId: json['item_id'],
      itemName: json['item_name'],
      category: json['category'],
      quantitySold: json['quantity_sold'],
      sellingPrice: json['selling_price'].toDouble(),
      totalPrice: json['total_price'].toDouble(),
      saleDate: DateTime.parse(json['sale_date']),
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      paymentMethod: json['payment_method'],
      notes: json['notes'],
    );
  }

  String get formattedDate => DateFormat('MMM dd, yyyy').format(saleDate);
  String get formattedTime => DateFormat('hh:mm a').format(saleDate);
} 