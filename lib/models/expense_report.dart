import 'package:flutter/foundation.dart';

class ExpenseReport {
  final String id;
  final String description;
  final DateTime date;
  final String category;
  final double amount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseReport({
    required this.id,
    required this.description,
    required this.date,
    required this.category,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  static const List<String> categories = [
    'Maintenance',
    'Utilities',
    'Supplies',
    'Rent',
    'Salaries',
    'Marketing',
    'Transportation',
    'Insurance',
    'Misc',
  ];

  factory ExpenseReport.fromJson(Map<String, dynamic> json) {
    try {
      return ExpenseReport(
        id: json['id']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        date: json['date'] != null 
            ? DateTime.parse(json['date'].toString())
            : DateTime.now(),
        category: json['category']?.toString() ?? 'Misc',
        amount: (json['amount'] != null)
            ? (json['amount'] as num).toDouble()
            : 0.0,
        createdAt: json['created_at'] != null 
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now(),
        updatedAt: json['updated_at'] != null 
            ? DateTime.parse(json['updated_at'].toString())
            : DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error parsing expense report: $e');
      debugPrint('JSON data: $json');
      // Return a default expense report if parsing fails
      return ExpenseReport(
        id: '',
        description: 'Error parsing data',
        date: DateTime.now(),
        category: 'Misc',
        amount: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'date': date.toIso8601String(),
      'category': category,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
} 