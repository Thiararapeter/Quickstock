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
    this.estimatedCost = 0.0,
    this.status = RepairStatus.pending,
    required this.dateCreated,
    this.dateCompleted,
    this.usedPartIds = const [],
    this.technicianNotes,
    this.customerNotes,
    this.updatedAt,
  });

  factory RepairTicket.fromMap(Map<String, dynamic> map) {
    return RepairTicket(
      id: map['id'] ?? '',
      ticketNumber: map['ticket_number'] ?? '',
      trackingId: map['tracking_id'] ?? '',
      customerName: map['customer_name'] ?? '',
      customerPhone: map['customer_phone'] ?? '',
      deviceType: map['device_type'] ?? '',
      deviceModel: map['device_model'] ?? '',
      serialNumber: map['serial_number'] ?? '',
      problem: map['problem'] ?? '',
      diagnosis: map['diagnosis'] ?? '',
      estimatedCost: (map['estimated_cost'] ?? 0.0).toDouble(),
      status: RepairStatus.values.firstWhere(
        (e) => e.toString() == 'RepairStatus.${map['status'] ?? 'pending'}',
        orElse: () => RepairStatus.pending,
      ),
      dateCreated: DateTime.parse(map['date_created'] ?? DateTime.now().toIso8601String()),
      dateCompleted: map['date_completed'] != null ? DateTime.parse(map['date_completed']) : null,
      usedPartIds: List<String>.from(map['used_part_ids'] ?? []),
      technicianNotes: map['technician_notes'],
      customerNotes: map['customer_notes'],
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
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
      'status': status.name,
      'date_created': dateCreated.toIso8601String(),
      'date_completed': dateCompleted?.toIso8601String(),
      'used_part_ids': usedPartIds,
      'technician_notes': technicianNotes,
      'customer_notes': customerNotes,
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
    );
  }
} 