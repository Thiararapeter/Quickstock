import 'package:intl/intl.dart';

enum RepairStatus {
  pending('Pending'),
  inProgress('In Progress'),
  waitingForParts('Waiting for Parts'),
  completed('Completed'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const RepairStatus(this.label);
  final String label;
}

class RepairTicket {
  final String id;
  final String ticketNumber;
  final String trackingId;
  final String customerName;
  final String customerPhone;
  final String deviceType;
  final String deviceModel;
  final String serialNumber;
  final String problem;
  final String diagnosis;
  final double estimatedCost;
  final RepairStatus status;
  final DateTime dateCreated;
  final DateTime? dateCompleted;
  final List<String> usedPartIds;
  final String? technicianNotes;
  final String? customerNotes;
  final DateTime? updatedAt;
  final double cost;

  RepairTicket({
    required this.id,
    required this.ticketNumber,
    required this.trackingId,
    required this.customerName,
    required this.customerPhone,
    required this.deviceType,
    required this.deviceModel,
    required this.serialNumber,
    required this.problem,
    this.diagnosis = '',
    required this.estimatedCost,
    required this.status,
    required this.dateCreated,
    this.dateCompleted,
    this.usedPartIds = const [],
    this.technicianNotes,
    this.customerNotes,
    this.updatedAt,
    required this.cost,
  });

  factory RepairTicket.fromJson(Map<String, dynamic> json) {
    return RepairTicket(
      id: json['id'],
      ticketNumber: json['ticket_number'],
      trackingId: json['tracking_id'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      deviceType: json['device_type'],
      deviceModel: json['device_model'],
      serialNumber: json['serial_number'],
      problem: json['problem'],
      diagnosis: json['diagnosis'] ?? '',
      estimatedCost: (json['estimated_cost'] as num).toDouble(),
      status: RepairStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      dateCreated: DateTime.parse(json['date_created']),
      dateCompleted: json['date_completed'] != null 
          ? DateTime.parse(json['date_completed']) 
          : null,
      usedPartIds: List<String>.from(json['used_part_ids'] ?? []),
      technicianNotes: json['technician_notes'],
      customerNotes: json['customer_notes'],
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticket_number': ticketNumber,
      'tracking_id': trackingId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'device_type': deviceType,
      'device_model': deviceModel,
      'serial_number': serialNumber,
      'problem': problem,
      'diagnosis': diagnosis,
      'estimated_cost': estimatedCost,
      'status': status.toString().split('.').last,
      'date_created': dateCreated.toIso8601String(),
      'date_completed': dateCompleted?.toIso8601String(),
      'used_part_ids': usedPartIds,
      'technician_notes': technicianNotes,
      'customer_notes': customerNotes,
      'updated_at': updatedAt?.toIso8601String(),
      'cost': cost,
    };
  }

  String get formattedDateCreated => 
      DateFormat('MMM dd, yyyy').format(dateCreated);

  String get formattedDateCompleted => dateCompleted != null
      ? DateFormat('MMM dd, yyyy').format(dateCompleted!)
      : 'Not completed';

  String get formattedEstimatedCost =>
      NumberFormat.currency(symbol: 'KSH ', decimalDigits: 2).format(estimatedCost);

  RepairTicket copyWith({
    String? id,
    String? ticketNumber,
    String? trackingId,
    String? customerName,
    String? customerPhone,
    String? deviceType,
    String? deviceModel,
    String? serialNumber,
    String? problem,
    String? diagnosis,
    double? estimatedCost,
    RepairStatus? status,
    DateTime? dateCreated,
    DateTime? dateCompleted,
    List<String>? usedPartIds,
    String? technicianNotes,
    String? customerNotes,
    DateTime? updatedAt,
    double? cost,
  }) {
    return RepairTicket(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      trackingId: trackingId ?? this.trackingId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deviceType: deviceType ?? this.deviceType,
      deviceModel: deviceModel ?? this.deviceModel,
      serialNumber: serialNumber ?? this.serialNumber,
      problem: problem ?? this.problem,
      diagnosis: diagnosis ?? this.diagnosis,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      status: status ?? this.status,
      dateCreated: dateCreated ?? this.dateCreated,
      dateCompleted: dateCompleted ?? this.dateCompleted,
      usedPartIds: usedPartIds ?? this.usedPartIds,
      technicianNotes: technicianNotes ?? this.technicianNotes,
      customerNotes: customerNotes ?? this.customerNotes,
      updatedAt: updatedAt ?? this.updatedAt,
      cost: cost ?? this.cost,
    );
  }
} 