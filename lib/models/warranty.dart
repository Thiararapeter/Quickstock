import 'package:uuid/uuid.dart';

class Warranty {
  String get id => _id ?? const Uuid().v4();
  final String? _id;
  final String itemId;
  final DateTime startDate;
  final DateTime endDate;
  final String period;
  final String supplier;
  final String terms;
  final DateTime createdAt;
  final DateTime updatedAt;

  Warranty({
    String? id,
    required this.itemId,
    required this.startDate,
    required this.endDate,
    required this.period,
    required this.supplier,
    this.terms = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    _id = id,
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isExpiringSoon => 
    DateTime.now().isBefore(endDate) && 
    DateTime.now().isAfter(endDate.subtract(const Duration(days: 30)));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'period': period,
      'supplier': supplier,
      'terms': terms,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Warranty.fromMap(Map<String, dynamic> map) {
    return Warranty(
      id: map['id'],
      itemId: map['item_id'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      period: map['period'],
      supplier: map['supplier'],
      terms: map['terms'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
} 