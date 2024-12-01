class POSSettings {
  final String id;
  final String userId;
  final String storeName;
  final String? tagline;
  final String? phone;
  final String? address;
  final String? website;
  final String? returnPolicy;
  final bool showVAT;
  final bool showBarcode;
  final bool showQR;
  final String? repairHeaderText;
  final bool showRepairQR;
  final bool showTicketBarcode;
  final String? repairFooterText;
  final DateTime createdAt;
  final DateTime updatedAt;

  POSSettings({
    required this.id,
    required this.userId,
    required this.storeName,
    this.tagline,
    this.phone,
    this.address,
    this.website,
    this.returnPolicy,
    this.showVAT = true,
    this.showBarcode = true,
    this.showQR = true,
    this.repairHeaderText,
    this.showRepairQR = true,
    this.showTicketBarcode = true,
    this.repairFooterText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory POSSettings.fromJson(Map<String, dynamic> json) {
    return POSSettings(
      id: json['id'],
      userId: json['user_id'],
      storeName: json['store_name'],
      tagline: json['tagline'],
      phone: json['phone'],
      address: json['address'],
      website: json['website'],
      returnPolicy: json['return_policy'],
      showVAT: json['show_vat'] ?? true,
      showBarcode: json['show_barcode'] ?? true,
      showQR: json['show_qr'] ?? true,
      repairHeaderText: json['repair_header_text'],
      showRepairQR: json['show_repair_qr'] ?? true,
      showTicketBarcode: json['show_ticket_barcode'] ?? true,
      repairFooterText: json['repair_footer_text'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'store_name': storeName,
      'tagline': tagline,
      'phone': phone,
      'address': address,
      'website': website,
      'return_policy': returnPolicy,
      'show_vat': showVAT,
      'show_barcode': showBarcode,
      'show_qr': showQR,
      'repair_header_text': repairHeaderText,
      'show_repair_qr': showRepairQR,
      'show_ticket_barcode': showTicketBarcode,
      'repair_footer_text': repairFooterText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  POSSettings copyWith({
    String? storeName,
    String? tagline,
    String? phone,
    String? address,
    String? website,
    String? returnPolicy,
    bool? showVAT,
    bool? showBarcode,
    bool? showQR,
    String? repairHeaderText,
    bool? showRepairQR,
    bool? showTicketBarcode,
    String? repairFooterText,
  }) {
    return POSSettings(
      id: id,
      userId: userId,
      storeName: storeName ?? this.storeName,
      tagline: tagline ?? this.tagline,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      website: website ?? this.website,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      showVAT: showVAT ?? this.showVAT,
      showBarcode: showBarcode ?? this.showBarcode,
      showQR: showQR ?? this.showQR,
      repairHeaderText: repairHeaderText ?? this.repairHeaderText,
      showRepairQR: showRepairQR ?? this.showRepairQR,
      showTicketBarcode: showTicketBarcode ?? this.showTicketBarcode,
      repairFooterText: repairFooterText ?? this.repairFooterText,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
} 