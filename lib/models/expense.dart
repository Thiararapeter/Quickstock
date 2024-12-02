class Expense {
  final String id;
  final String name;
  final DateTime date;
  final String category;
  final double amount;
  final String description;

  Expense({
    required this.id,
    required this.name,
    required this.date,
    required this.category,
    required this.amount,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'category': category,
      'amount': amount,
      'description': description,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Expense',
      date: json['date'] != null 
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      category: json['category']?.toString() ?? 'Misc',
      amount: json['amount'] != null 
          ? (json['amount'] as num).toDouble()
          : 0.0,
      description: json['description']?.toString() ?? '',
    );
  }
} 