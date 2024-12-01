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
      id: json['id'],
      name: json['name'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      amount: json['amount'].toDouble(),
      description: json['description'],
    );
  }
} 