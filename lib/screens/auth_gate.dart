import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/password.dart';
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
  bool _restoring = true;
  String _currentLoggedInUserId = '';
  String _userRole = '';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _sessionKey = 'shiftflow_session';

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  // Survive browser refreshes: restore the last session from local storage.
  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionKey);
      if (raw != null) {
        final s = jsonDecode(raw) as Map<String, dynamic>;
        if (s['workspaceId'] == 'system_root') {
          _activeWorkspace = RestaurantTenant(id: 'system_root', name: 'SUPER ADMIN GOD MODE', adminPassword: '');
          _userRole = 'superadmin'; _isLoggedIn = true;
        } else {
          final doc = await _db.collection('restaurants').doc(s['workspaceId']).get();
          if (doc.exists) {
            _activeWorkspace = RestaurantTenant(id: doc.id, name: doc['name'], adminPassword: doc['adminPassword']);
            _userRole = s['role'] ?? '';
            _currentLoggedInUserId = s['userId'] ?? '';
            _isLoggedIn = _userRole.isNotEmpty;
            _migrateLegacyShiftDates(doc.id);
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _restoring = false);
  }

  // One-time per workspace: stamp legacy shifts (no month/year) with the
  // current month so they stop repeating in every month. Guarded by a flag
  // on the tenant doc; safe to call repeatedly.
  Future<void> _migrateLegacyShiftDates(String wsId) async {
    try {
      final ws = _db.collection('restaurants').doc(wsId);
      final tenant = await ws.get();
      if ((tenant.data()?['shiftDatesMigrated'] ?? false) == true) return;
      final shifts = await ws.collection('shifts').get();
      final now = DateTime.now();
      final batch = _db.batch();
      for (final d in shifts.docs) {
        final data = d.data();
        if (data['month'] == null || data['year'] == null) {
          batch.update(d.reference, {'month': now.month, 'year': now.year});
        }
      }
      batch.set(ws, {'shiftDatesMigrated': true}, SetOptions(merge: true));
      await batch.commit();
    } catch (_) {}
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode({'workspaceId': _activeWorkspace?.id, 'role': _userRole, 'userId': _currentLoggedInUserId}));
  }

  void _verifyWorkspace(String workspaceId) async {
    final cleanId = workspaceId.toLowerCase().trim();
    if (cleanId == 'system_root') {
      setState(() => _activeWorkspace = RestaurantTenant(id: 'system_root', name: 'SUPER ADMIN GOD MODE', adminPassword: 'masterkey'));
      return;
    }
    final doc = await _db.collection('restaurants').doc(cleanId).get();
    if (doc.exists) {
      setState(() => _activeWorkspace = RestaurantTenant(id: doc.id, name: doc['name'], adminPassword: doc['adminPassword']));
      _migrateLegacyShiftDates(cleanId);
    } else if (cleanId == 'mcd_01') {
      await _db.collection('restaurants').doc('mcd_01').set({'name': "McDonald's Central", 'adminPassword': "admin"});
      await _db.collection('restaurants').doc('mcd_01').collection('employees').add({'restaurantId': 'mcd_01', 'name': 'Elena Valdes', 'role': 'Shift Lead', 'username': 'elena', 'password': '123'});
      _verifyWorkspace('mcd_01');
    }
  }

  void _login(String username, String password) async {
    if (_activeWorkspace == null) return;
    final ws = _activeWorkspace!;
    if (ws.id == 'system_root' && username == 'superadmin' && password == 'masterkey') {
      setState(() { _userRole = 'superadmin'; _isLoggedIn = true; });
      _saveSession();
      return;
    }
    final uname = username.toLowerCase().trim();
    if (uname == 'admin') {
      if (verifyPassword(password, ws.adminPassword, ws.id)) {
        // Upgrade a legacy plaintext admin password on first login.
        if (!isHashed(ws.adminPassword)) _db.collection('restaurants').doc(ws.id).update({'adminPassword': encodePassword(password, ws.id)});
        setState(() { _userRole = 'admin'; _currentLoggedInUserId = 'admin'; _isLoggedIn = true; });
        _saveSession();
      }
      return;
    }
    // Query by username only — passwords are verified (and legacy ones
    // upgraded to salted hashes) locally, never compared in the query.
    final query = await _db.collection('restaurants').doc(ws.id).collection('employees').where('username', isEqualTo: uname).get();
    for (final d in query.docs) {
      final data = d.data();
      if ((data['archived'] ?? false) == true) continue; // soft-deleted
      final stored = (data['password'] ?? '') as String;
      if (!verifyPassword(password, stored, '${ws.id}:$uname')) continue;
      if (!isHashed(stored)) d.reference.update({'password': encodePassword(password, '${ws.id}:$uname')});
      setState(() { _userRole = 'employee'; _currentLoggedInUserId = d.id; _isLoggedIn = true; });
      _saveSession();
      return;
    }
  }

  void _logout() {
    SharedPreferences.getInstance().then((p) => p.remove(_sessionKey));
    setState(() { _isLoggedIn = false; _userRole = ''; _currentLoggedInUserId = ''; _activeWorkspace = null; });
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_activeWorkspace == null) return WorkspaceGateScreen(onVerify: _verifyWorkspace);
    if (!_isLoggedIn) return LoginScreen(restaurantName: _activeWorkspace!.name, onLogin: _login, onBack: () => setState(()=> _activeWorkspace = null));
    if (_userRole == 'superadmin') return SuperAdminShell(onLogout: _logout);

    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('restaurants').doc(_activeWorkspace!.id).collection('employees').snapshots(),
      builder: (context, empSnapshot) {
        if (!empSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final activeEmployees = empSnapshot.data!.docs.map((doc) => EmployeeData.fromFirestore(doc)).where((e) => !e.archived).toList();

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
