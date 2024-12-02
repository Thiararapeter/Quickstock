class Receipt {
  final String id;
  final String receiptNumber;
  final double totalAmount;
  final String? customerName;
  final String? customerPhone;
  final String paymentMethod;
  final String? transactionCode;
  final DateTime saleDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Receipt({
    required this.id,
    required this.receiptNumber,
    required this.totalAmount,
    this.customerName,
    this.customerPhone,
    required this.paymentMethod,
    this.transactionCode,
    required this.saleDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'],
      receiptNumber: json['receipt_number'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      paymentMethod: json['payment_method'],
      transactionCode: json['transaction_code'],
      saleDate: DateTime.parse(json['sale_date']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receipt_number': receiptNumber,
      'total_amount': totalAmount,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'payment_method': paymentMethod,
      'transaction_code': transactionCode,
      'sale_date': saleDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
} 