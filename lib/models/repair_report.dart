class RepairReport {
  final String status;
  final int ticketCount;
  final double totalRevenue;
  final double averageRepairCost;
  final double repairCompletionRate;

  RepairReport({
    required this.status,
    required this.ticketCount,
    required this.totalRevenue,
    required this.averageRepairCost,
    required this.repairCompletionRate,
  });

  factory RepairReport.fromJson(Map<String, dynamic> json) {
    return RepairReport(
      status: json['status']?.toString() ?? 'Unknown',
      ticketCount: json['ticket_count'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      averageRepairCost: (json['average_repair_cost'] as num?)?.toDouble() ?? 0.0,
      repairCompletionRate: (json['repair_completion_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
} 