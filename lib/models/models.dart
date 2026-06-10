import 'package:cloud_firestore/cloud_firestore.dart';

// ==========================================
// CLOUD DATA MODELS
// ==========================================
class RestaurantTenant {
  String id; String name; String adminPassword;
  RestaurantTenant({required this.id, required this.name, required this.adminPassword});
}

class EmployeeData {
  String id; String restaurantId; String name; String role; String username; String password;
  // App-level permission role: 'admin' | 'manager' | 'employee'.
  // Optional Firestore field — existing docs without it default to 'employee'.
  String appRole;
  // Team Management v2 optional fields: contact email, hourly rate for
  // labor-cost reports, soft-delete flag (archived staff can't log in).
  String? email; num hourlyRate; bool archived;
  EmployeeData({required this.id, required this.restaurantId, required this.name, required this.role, required this.username, required this.password, this.appRole = 'employee', this.email, this.hourlyRate = 0, this.archived = false});
  bool get canManageShifts => appRole == 'admin' || appRole == 'manager';
  factory EmployeeData.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return EmployeeData(id: doc.id, restaurantId: data['restaurantId'] ?? '', name: data['name'] ?? '', role: data['role'] ?? '', username: data['username'] ?? '', password: data['password'] ?? '', appRole: data['appRole'] ?? 'employee', email: data['email'], hourlyRate: data['hourlyRate'] ?? 0, archived: data['archived'] ?? false);
  }
}

class ShiftData {
  String id; String restaurantId; String employeeId; String employeeName; String timeWindow; int dayOfMonth; int durationHours;
  // Schedule v2 optional fields. Legacy docs leave them null:
  // null month/year = the shift matches every month (original behavior);
  // null start/end minutes = times are derived from the timeWindow string.
  int? month; int? year; int? startMinutes; int? endMinutes;
  // Feature 5: unassigned shift posted to the open-shift board.
  bool isOpenShift;
  ShiftData({required this.id, required this.restaurantId, required this.employeeId, required this.employeeName, required this.timeWindow, required this.dayOfMonth, this.durationHours = 8, this.month, this.year, this.startMinutes, this.endMinutes, this.isOpenShift = false});
  factory ShiftData.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ShiftData(id: doc.id, restaurantId: data['restaurantId'] ?? '', employeeId: data['employeeId'] ?? '', employeeName: data['employeeName'] ?? '', timeWindow: data['timeWindow'] ?? '', dayOfMonth: data['dayOfMonth'] ?? 1, durationHours: data['durationHours'] ?? 8, month: data['month'], year: data['year'], startMinutes: data['startMinutes'], endMinutes: data['endMinutes'], isOpenShift: data['isOpenShift'] ?? false);
  }
}

// Feature 3: a reusable week pattern. Each pattern entry is
// {weekday: 1-7 (Mon-Sun), startMinutes, endMinutes} — no employee,
// assignment is suggested at apply time.
class ShiftTemplateData {
  String id; String name; List<Map<String, dynamic>> pattern;
  ShiftTemplateData({required this.id, required this.name, required this.pattern});
  factory ShiftTemplateData.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ShiftTemplateData(id: doc.id, name: data['name'] ?? '', pattern: List<Map<String, dynamic>>.from((data['pattern'] ?? []).map((e) => Map<String, dynamic>.from(e))));
  }
}

class VacationData {
  String id; String restaurantId; String employeeName; String dates; String status;
  // Optional since Feature 4: ISO dates + employee id enable real leave
  // checks. Legacy docs only carry the display string in `dates`.
  String? employeeId; String? startDate; String? endDate;
  VacationData({required this.id, required this.restaurantId, required this.employeeName, required this.dates, this.status = 'Pending', this.employeeId, this.startDate, this.endDate});
  factory VacationData.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return VacationData(id: doc.id, restaurantId: data['restaurantId'] ?? '', employeeName: data['employeeName'] ?? '', dates: data['dates'] ?? '', status: data['status'] ?? 'Pending', employeeId: data['employeeId'], startDate: data['startDate'], endDate: data['endDate']);
  }
}
