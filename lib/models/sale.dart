import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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
  final String? transactionCode;
  final String? notes;
  final String receiptId;

  Sale({
    String? id,
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
    this.transactionCode,
    this.notes,
    required this.receiptId,
  }) : this.id = id ?? const Uuid().v4();

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      itemId: json['item_id'],
      itemName: json['item_name'],
      category: json['category'],
      quantitySold: json['quantity_sold'],
      sellingPrice: (json['selling_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      saleDate: DateTime.parse(json['sale_date']),
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      paymentMethod: json['payment_method'],
      transactionCode: json['transaction_code'],
      notes: json['notes'],
      receiptId: json['receipt_id'],
    );
  }

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
      'transaction_code': transactionCode,
      'notes': notes,
      'receipt_id': receiptId,
    };
  }

  String get formattedDate => DateFormat('MMM dd, yyyy').format(saleDate);
  String get formattedTime => DateFormat('hh:mm a').format(saleDate);
} 