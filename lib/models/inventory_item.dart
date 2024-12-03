import 'package:intl/intl.dart';

class InventoryItem {
  final String id;
  final String name;
  final String serialNumber;
  final double purchasePrice;
  final double sellingPrice;
  final String category;
  final int quantity;
  final String condition;
  final DateTime dateAdded;
  final DateTime updatedAt;
  final bool hasWarranty;

  InventoryItem({
    required this.id,
    required this.name,
    required this.serialNumber,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.category,
    required this.quantity,
    required this.condition,
    required this.dateAdded,
    DateTime? updatedAt,
    this.hasWarranty = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  // Add fromJson constructor
  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      serialNumber: json['serial_number'] as String,
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      category: json['category'] as String,
      quantity: json['quantity'] as int,
      condition: json['condition'] as String,
      dateAdded: DateTime.parse(json['date_added'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      hasWarranty: json['has_warranty'] as bool? ?? false,
    );
  }

  // Alias for fromJson to maintain compatibility
  factory InventoryItem.fromMap(Map<String, dynamic> map) => InventoryItem.fromJson(map);

  // Add toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'serial_number': serialNumber,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'category': category,
      'quantity': quantity,
      'condition': condition,
      'date_added': dateAdded.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'has_warranty': hasWarranty,
    };
  }

  // Add copyWith method
  InventoryItem copyWith({
    String? id,
    String? name,
    String? serialNumber,
    double? purchasePrice,
    double? sellingPrice,
    String? category,
    int? quantity,
    String? condition,
    DateTime? dateAdded,
    DateTime? updatedAt,
    bool? hasWarranty,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      serialNumber: serialNumber ?? this.serialNumber,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      condition: condition ?? this.condition,
      dateAdded: dateAdded ?? this.dateAdded,
      updatedAt: updatedAt ?? this.updatedAt,
      hasWarranty: hasWarranty ?? this.hasWarranty,
    );
  }

  // Add toMap method
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'serial_number': serialNumber,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'category': category,
      'quantity': quantity,
      'condition': condition,
      'date_added': dateAdded.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'has_warranty': hasWarranty,
    };
  }

  // Add toString method for debugging
  @override
  String toString() {
    return 'InventoryItem(id: $id, name: $name, serialNumber: $serialNumber, '
        'purchasePrice: $purchasePrice, sellingPrice: $sellingPrice, '
        'category: $category, quantity: $quantity, condition: $condition, '
        'dateAdded: $dateAdded, updatedAt: $updatedAt, hasWarranty: $hasWarranty)';
  }

  // Format price with currency
  String get formattedPurchasePrice => 
      NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(purchasePrice);
  
  String get formattedSellingPrice => 
      NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(sellingPrice);
  
  // Format date
  String get formattedDate => 
      DateFormat('MMM dd, yyyy').format(dateAdded);
} 