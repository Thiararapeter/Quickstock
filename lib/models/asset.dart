class Asset {
  final String id;
  final String name;
  final String type;
  final String serialNumber;
  final double purchasePrice;
  final DateTime purchaseDate;
  final String condition;
  final String location;
  final DateTime dateAdded;
  final DateTime updatedAt;

  Asset({
    required this.id,
    required this.name,
    required this.type,
    required this.serialNumber,
    required this.purchasePrice,
    required this.purchaseDate,
    required this.condition,
    required this.location,
    required this.dateAdded,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'serial_number': serialNumber,
      'purchase_price': purchasePrice,
      'purchase_date': purchaseDate.toIso8601String(),
      'condition': condition,
      'location': location,
      'date_added': dateAdded.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      serialNumber: map['serial_number'],
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      purchaseDate: DateTime.parse(map['purchase_date']),
      condition: map['condition'],
      location: map['location'],
      dateAdded: DateTime.parse(map['date_added']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
} 