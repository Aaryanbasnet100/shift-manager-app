import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/models.dart';
import 'package:flutter_application_1/services/austria_time.dart';
import 'package:flutter_application_1/services/availability.dart';
import 'package:flutter_application_1/services/password.dart';
import 'package:flutter_application_1/services/shift_time.dart';

ShiftData shift({String emp = 'e1', int day = 15, int? month, int? year, String window = 'Morning (06:00 - 14:00)', int? startMin, int? endMin}) =>
    ShiftData(id: 's1', restaurantId: 'ws', employeeId: emp, employeeName: 'Test', timeWindow: window, dayOfMonth: day, month: month, year: year, startMinutes: startMin, endMinutes: endMin);

void main() {
  group('shift_time', () {
    test('parseWindow extracts hour range', () {
      expect(parseWindow('Morning (06:00 - 14:00)'), (start: 6, end: 14));
      expect(parseWindow('08:30 - 17:00'), (start: 8, end: 17));
      expect(parseWindow('free text'), isNull);
    });

    test('effective minutes prefer explicit fields over the window string', () {
      expect(effectiveStartMinutes(shift(startMin: 510)), 510);
      expect(effectiveStartMinutes(shift()), 6 * 60);
      expect(effectiveEndMinutes(shift(endMin: 1020)), 1020);
      expect(effectiveEndMinutes(shift()), 14 * 60);
    });

    test('occursOn: dated shifts match only their date, legacy match any month', () {
      final dated = shift(month: 6, year: 2026);
      expect(occursOn(dated, DateTime(2026, 6, 15)), isTrue);
      expect(occursOn(dated, DateTime(2026, 7, 15)), isFalse);
      final legacy = shift();
      expect(occursOn(legacy, DateTime(2026, 6, 15)), isTrue);
      expect(occursOn(legacy, DateTime(2026, 7, 15)), isTrue);
      expect(occursOn(legacy, DateTime(2026, 7, 16)), isFalse);
    });

    test('isShiftActiveNow covers the window, overnight counts the evening', () {
      final s = shift(month: 6, year: 2026);
      expect(isShiftActiveNow(s, DateTime(2026, 6, 15, 7)), isTrue);
      expect(isShiftActiveNow(s, DateTime(2026, 6, 15, 14)), isFalse);
      final night = shift(month: 6, year: 2026, window: 'Night (22:00 - 06:00)');
      expect(isShiftActiveNow(night, DateTime(2026, 6, 15, 23)), isTrue);
      expect(isShiftActiveNow(night, DateTime(2026, 6, 15, 21)), isFalse);
    });

    test('fmtMinutes pads to HH:MM', () {
      expect(fmtMinutes(0), '00:00');
      expect(fmtMinutes(545), '09:05');
      expect(fmtMinutes(1439), '23:59');
    });
  });

  group('availability', () {
    test('missing doc or key defaults to available', () {
      expect(availabilityStatus(null, 3), 'available');
      expect(availabilityStatus({'wd1': 'unavailable'}, 3), 'available');
      expect(availabilityStatus({'wd3': 'preferred'}, 3), 'preferred');
    });
  });

  group('password', () {
    test('hashes verify and legacy plaintext still works', () {
      final stored = encodePassword('secret', 'ws:elena');
      expect(isHashed(stored), isTrue);
      expect(verifyPassword('secret', stored, 'ws:elena'), isTrue);
      expect(verifyPassword('wrong', stored, 'ws:elena'), isFalse);
      expect(verifyPassword('secret', stored, 'other:salt'), isFalse);
      expect(verifyPassword('123', '123', 'any'), isTrue); // legacy
    });
  });

  group('austria_time', () {
    test('CEST in summer, CET in winter', () {
      expect(isCEST(DateTime.utc(2026, 7, 1)), isTrue);
      expect(isCEST(DateTime.utc(2026, 1, 1)), isFalse);
    });
  });

  group('models', () {
    test('EmployeeData role gate defaults to least privilege', () {
      final emp = EmployeeData(id: 'x', restaurantId: 'ws', name: 'N', role: 'Staff', username: 'n', password: 'p');
      expect(emp.appRole, 'employee');
      expect(emp.canManageShifts, isFalse);
      expect(emp.archived, isFalse);
      final mgr = EmployeeData(id: 'x', restaurantId: 'ws', name: 'N', role: 'Staff', username: 'n', password: 'p', appRole: 'manager');
      expect(mgr.canManageShifts, isTrue);
    });
  });
}
