import 'package:flutter_test/flutter_test.dart';
import 'package:mayor_apps/features/dashboard/models/department_compliance_model.dart';

void main() {
  group('Statutory ARTA SLA Compliance Calculation Tests', () {
    test('Bug Scenario: Done = 0, Overdue = 2 must resolve to 0.0% Non-Compliant', () {
      final model = DepartmentComplianceModel.fromJson({
        'officeCode': 'ENG',
        'officeName': 'Municipal Engineering Office',
        'complianceRate': 100.0, // Buggy backend sends 100.0!
        'completed': 0,
        'pending': 1,
        'overdue': 2,
        'total': 3,
      });

      expect(model.complianceRate, 0.0);
      expect(model.statusLabel, 'Non-Compliant');
      expect(model.isAtRisk, true);
      expect(model.isCompliant, false);
    });

    test('Overdue breach: Done = 8, Overdue = 2 must resolve to 80.0% Moderate', () {
      final model = DepartmentComplianceModel.fromJson({
        'officeCode': 'BPLO',
        'officeName': 'Business Permits & Licensing',
        'complianceRate': 100.0, // Buggy backend sends 100.0!
        'completed': 8,
        'pending': 3,
        'overdue': 2,
        'total': 13,
      });

      // 8 / (8 + 2) * 100 = 80.0%
      expect(model.complianceRate, 80.0);
      expect(model.statusLabel, 'Moderate');
      expect(model.isModerate, true);
    });

    test('Clean Compliant: Done = 10, Overdue = 0 must resolve to 100.0% Compliant', () {
      final model = DepartmentComplianceModel.fromJson({
        'officeCode': 'MHO',
        'officeName': 'Municipal Health Office',
        'completed': 10,
        'pending': 2,
        'overdue': 0,
        'total': 12,
      });

      expect(model.complianceRate, 100.0);
      expect(model.statusLabel, 'Compliant');
      expect(model.isCompliant, true);
    });

    test('Clean Slate: Total = 0 (No requests) must resolve to 100.0% Compliant', () {
      final model = DepartmentComplianceModel.fromJson({
        'officeCode': 'TOUR',
        'officeName': 'Tourism Office',
        'completed': 0,
        'pending': 0,
        'overdue': 0,
        'total': 0,
      });

      expect(model.complianceRate, 100.0);
      expect(model.statusLabel, 'Compliant');
    });
  });
}

