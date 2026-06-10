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
  EmployeeData({required this.id, required this.restaurantId, required this.name, required this.role, required this.username, required this.password, this.appRole = 'employee'});
  bool get canManageShifts => appRole == 'admin' || appRole == 'manager';
  factory EmployeeData.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return EmployeeData(id: doc.id, restaurantId: data['restaurantId'] ?? '', name: data['name'] ?? '', role: data['role'] ?? '', username: data['username'] ?? '', password: data['password'] ?? '', appRole: data['appRole'] ?? 'employee');
  }
}

class ShiftData {
  String id; String restaurantId; String employeeId; String employeeName; String timeWindow; int dayOfMonth; int durationHours;
  // Schedule v2 optional fields. Legacy docs leave them null:
  // null month/year = the shift matches every month (original behavior);
  // null start/end minutes = times are derived from the timeWindow string.
  int? month; int? year; int? startMinutes; int? endMinutes;
  ShiftData({required this.id, required this.restaurantId, required this.employeeId, required this.employeeName, required this.timeWindow, required this.dayOfMonth, this.durationHours = 8, this.month, this.year, this.startMinutes, this.endMinutes});
  factory ShiftData.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ShiftData(id: doc.id, restaurantId: data['restaurantId'] ?? '', employeeId: data['employeeId'] ?? '', employeeName: data['employeeName'] ?? '', timeWindow: data['timeWindow'] ?? '', dayOfMonth: data['dayOfMonth'] ?? 1, durationHours: data['durationHours'] ?? 8, month: data['month'], year: data['year'], startMinutes: data['startMinutes'], endMinutes: data['endMinutes']);
  }
}

class VacationData {
  String id; String restaurantId; String employeeName; String dates; String status;
  VacationData({required this.id, required this.restaurantId, required this.employeeName, required this.dates, this.status = 'Pending'});
  factory VacationData.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return VacationData(id: doc.id, restaurantId: data['restaurantId'] ?? '', employeeName: data['employeeName'] ?? '', dates: data['dates'] ?? '', status: data['status'] ?? 'Pending');
  }
}
