import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'admin_shell.dart';
import 'employee_shell.dart';
import 'login_screen.dart';
import 'manager_shell.dart';
import 'super_admin_shell.dart';
import 'workspace_gate_screen.dart';

// ==========================================
// FIREBASE AUTH & ROUTING KERNEL
// ==========================================
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  RestaurantTenant? _activeWorkspace;
  bool _isLoggedIn = false;
  String _currentLoggedInUserId = '';
  String _userRole = '';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _verifyWorkspace(String workspaceId) async {
    final cleanId = workspaceId.toLowerCase().trim();
    if (cleanId == 'system_root') {
      setState(() => _activeWorkspace = RestaurantTenant(id: 'system_root', name: 'SUPER ADMIN GOD MODE', adminPassword: 'masterkey'));
      return;
    }
    final doc = await _db.collection('restaurants').doc(cleanId).get();
    if (doc.exists) {
      setState(() => _activeWorkspace = RestaurantTenant(id: doc.id, name: doc['name'], adminPassword: doc['adminPassword']));
    } else if (cleanId == 'mcd_01') {
      await _db.collection('restaurants').doc('mcd_01').set({'name': "McDonald's Central", 'adminPassword': "admin"});
      await _db.collection('restaurants').doc('mcd_01').collection('employees').add({'restaurantId': 'mcd_01', 'name': 'Elena Valdes', 'role': 'Shift Lead', 'username': 'elena', 'password': '123'});
      _verifyWorkspace('mcd_01');
    }
  }

  void _login(String username, String password) async {
    if (_activeWorkspace == null) return;
    if (_activeWorkspace!.id == 'system_root' && username == 'superadmin' && password == 'masterkey') {
      setState(() { _userRole = 'superadmin'; _isLoggedIn = true; });
      return;
    }
    if (username.toLowerCase() == 'admin' && password == _activeWorkspace!.adminPassword) {
      setState(() { _userRole = 'admin'; _currentLoggedInUserId = 'admin'; _isLoggedIn = true; });
    } else {
      final query = await _db.collection('restaurants').doc(_activeWorkspace!.id).collection('employees').where('username', isEqualTo: username.toLowerCase()).where('password', isEqualTo: password).get();
      if (query.docs.isNotEmpty) {
        setState(() { _userRole = 'employee'; _currentLoggedInUserId = query.docs.first.id; _isLoggedIn = true; });
      }
    }
  }

  void _logout() => setState(() { _isLoggedIn = false; _userRole = ''; _currentLoggedInUserId = ''; _activeWorkspace = null; });

  @override
  Widget build(BuildContext context) {
    if (_activeWorkspace == null) return WorkspaceGateScreen(onVerify: _verifyWorkspace);
    if (!_isLoggedIn) return LoginScreen(restaurantName: _activeWorkspace!.name, onLogin: _login, onBack: () => setState(()=> _activeWorkspace = null));
    if (_userRole == 'superadmin') return SuperAdminShell(onLogout: _logout);

    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('restaurants').doc(_activeWorkspace!.id).collection('employees').snapshots(),
      builder: (context, empSnapshot) {
        if (!empSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final activeEmployees = empSnapshot.data!.docs.map((doc) => EmployeeData.fromFirestore(doc)).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: _db.collection('restaurants').doc(_activeWorkspace!.id).collection('shifts').snapshots(),
          builder: (context, shiftSnapshot) {
            if (!shiftSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
            final activeShifts = shiftSnapshot.data!.docs.map((doc) => ShiftData.fromFirestore(doc)).toList();

            return StreamBuilder<QuerySnapshot>(
              stream: _db.collection('restaurants').doc(_activeWorkspace!.id).collection('vacations').snapshots(),
              builder: (context, vacSnapshot) {
                if (!vacSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
                final activeVacations = vacSnapshot.data!.docs.map((doc) => VacationData.fromFirestore(doc)).toList();

                if (_userRole == 'admin') {
                  return AdminShell(restaurantName: _activeWorkspace!.name, workspaceId: _activeWorkspace!.id, onLogout: _logout, employees: activeEmployees, shifts: activeShifts, vacations: activeVacations);
                } else {
                  final currentEmp = activeEmployees.firstWhere((e) => e.id == _currentLoggedInUserId);
                  // Issue 4: route by the appRole stored on the employee doc.
                  if (currentEmp.appRole == 'admin') {
                    return AdminShell(restaurantName: _activeWorkspace!.name, workspaceId: _activeWorkspace!.id, onLogout: _logout, employees: activeEmployees, shifts: activeShifts, vacations: activeVacations);
                  }
                  if (currentEmp.appRole == 'manager') {
                    return ManagerShell(restaurantName: _activeWorkspace!.name, workspaceId: _activeWorkspace!.id, onLogout: _logout, currentManager: currentEmp, employees: activeEmployees, shifts: activeShifts, vacations: activeVacations);
                  }
                  return EmployeeShell(restaurantName: _activeWorkspace!.name, onLogout: _logout, currentEmployee: currentEmp, allShifts: activeShifts, vacations: activeVacations, allEmployees: activeEmployees);
                }
              }
            );
          }
        );
      }
    );
  }
}
