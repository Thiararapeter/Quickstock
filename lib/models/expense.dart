class Expense {
  final String id;
  final String name;
  final DateTime date;
  final String category;
  final double amount;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;

  Expense({
    required this.id,
    required this.name,
    required this.date,
    required this.category,
    required this.amount,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now(),
    this.userId = userId ?? '';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'category': category,
      'amount': amount,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      date: json['date'] != null 
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      category: json['category']?.toString() ?? Expense.categories.first,
      amount: json['amount'] != null
          ? (json['amount'] as num).toDouble()
          : 0.0,
      description: json['description']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
      userId: json['user_id']?.toString() ?? '',
    );
  }

  Expense copyWith({
    String? id,
    String? name,
    DateTime? date,
    String? category,
    double? amount,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return Expense(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }

  static List<String> get categories => [
    'Maintenance',
    'Utilities',
    'Supplies',
    'Rent',
    'Salaries',
    'Marketing',
    'Transportation',
    'Insurance',
    'Misc'
  ];
}