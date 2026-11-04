import 'package:flutter/material.dart';

class DepartmentComplianceModel {
  final String officeCode;
  final String officeName;
  final double complianceRate;
  final int completed;
  final int pending;
  final int overdue;
  final int total;

  DepartmentComplianceModel({
    required this.officeCode,
    required this.officeName,
    required this.complianceRate,
    required this.completed,
    required this.pending,
    required this.overdue,
    required this.total,
  });

  /// Standard Statutory ARTA SLA Compliance Calculation
  /// Formula: Completed / (Completed + Overdue) * 100
  /// Strict Edge Case: If Completed = 0 and Overdue > 0, Rate = 0.0%
  static double computeComplianceRate({
    required int completed,
    required int overdue,
    required int total,
    double? serverRate,
  }) {
    // Edge Case 1: Overdue breaches exist but zero requests completed on time
    if (overdue > 0 && completed == 0) {
      return 0.0;
    }

    final evaluated = completed + overdue;
    // Standard Case: We have evaluated resolutions (completed + overdue)
    if (evaluated > 0) {
      final rate = (completed / evaluated) * 100.0;
      return double.parse(rate.clamp(0.0, 100.0).toStringAsFixed(1));
    }

    // Edge Case 2: No resolved transactions yet (either total = 0 or all pending within clock)
    if (total == 0) {
      return 100.0; // Clean slate (no breaches)
    }

    // If server passed a valid rate, use it, otherwise 100.0
    return serverRate != null ? serverRate.clamp(0.0, 100.0) : 100.0;
  }

  factory DepartmentComplianceModel.fromJson(Map<String, dynamic> json) {
    final completed = (json['completed'] as num?)?.toInt() ?? 0;
    final pending = (json['pending'] as num?)?.toInt() ?? 0;
    final overdue = (json['overdue'] as num?)?.toInt() ?? 0;
    final total = (json['total'] as num?)?.toInt() ?? (completed + pending + overdue);

    final rawServerRate = (json['complianceRate'] as num?)?.toDouble();

    // Use standardized formula to protect against backend miscalculations
    final computedRate = computeComplianceRate(
      completed: completed,
      overdue: overdue,
      total: total,
      serverRate: rawServerRate,
    );

    return DepartmentComplianceModel(
      officeCode: json['officeCode']?.toString() ?? '',
      officeName: json['officeName']?.toString() ?? 'Department Office',
      complianceRate: computedRate,
      completed: completed,
      pending: pending,
      overdue: overdue,
      total: total,
    );
  }

  // Statutory ARTA SLA Thresholds:
  // >= 90.0%: Compliant (Official Green Target)
  // 75.0% - 89.9%: Moderate (Amber Alert)
  // < 75.0%: Non-Compliant / At Risk (Rose Red Alert)
  bool get isCompliant => complianceRate >= 90.0 && overdue == 0;
  bool get isModerate => (complianceRate >= 75.0 && complianceRate < 90.0) || (complianceRate >= 90.0 && overdue > 0);
  bool get isAtRisk => complianceRate < 75.0;

  Color get statusColor {
    if (isCompliant) return const Color(0xFF10B981); // Emerald 500
    if (isModerate) return const Color(0xFFF59E0B); // Amber 500
    return const Color(0xFFF43F5E); // Rose 500
  }

  String get statusLabel {
    if (isCompliant) return "Compliant";
    if (isModerate) return "Moderate";
    return "Non-Compliant";
  }

  IconData get officeIcon {
    final code = officeCode.toUpperCase();
    if (code.contains('BPLO') || code.contains('PERMIT')) {
      return Icons.store_mall_directory_rounded;
    }
    if (code.contains('ENGINEER') || code.contains('BUILDING')) {
      return Icons.architecture_rounded;
    }
    if (code.contains('TREASURY') || code.contains('TREASURER')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (code.contains('CIVIL') || code.contains('REGISTRAR')) {
      return Icons.history_edu_rounded;
    }
    if (code.contains('RHU') || code.contains('HEALTH')) {
      return Icons.medical_services_rounded;
    }
    if (code.contains('ASSESSOR')) {
      return Icons.real_estate_agent_rounded;
    }
    if (code.contains('POSO') || code.contains('TRAFFIC')) {
      return Icons.local_police_rounded;
    }
    return Icons.domain_rounded;
  }
}
