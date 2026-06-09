import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'dart:async';

// ==========================================
// GLOBAL STATE & LOCALIZATION ENGINE
// ==========================================
final ValueNotifier<String> appLang = ValueNotifier('en');

final Map<String, Map<String, String>> dict = {
  'en': {
    'gateway': 'Enterprise Cloud Gateway', 'workspace': 'Workspace ID (e.g., mcd_01)', 'connect': 'CONNECT TO CLOUD NODE',
    'portal': 'Identity Portal', 'user': 'Username', 'pass': 'Password', 'auth': 'AUTHORIZE ACCESS',
    'shift_graph': 'Shift Graph', 'calendar': 'Calendar', 'vacation': 'Vacation', 'my_shifts': 'MY UPCOMING SHIFTS',
    'austria_time': 'Austrian Local Time', 'req_vacation': 'Request Vacation', 'self_schedule': 'Self-Schedule Shift',
    'pending': 'Pending', 'approved': 'Approved',
    // --- NEW FEATURES DICTIONARY ---
    'conflict_title': 'SHIFT CONFLICT', 'conflict_desc': 'A shift already exists on day ', 'dismiss': 'DISMISS',
    'morning': 'Morning (06:00 - 14:00)', 'afternoon': 'Afternoon (14:00 - 22:00)', 'night': 'Night (22:00 - 06:00)',
    'duration': 'Duration (Hours)', 'deploy_shift': 'EXECUTE DEPLOYMENT', 'monthly_hours': 'MONTHLY HOURS',
    'overtime': 'OVERTIME WARNING', 'request_swap': 'Request Swap', 'select_colleague': 'Select Colleague',
    'notifications': 'SYSTEM ALERTS', 'delete_emp': 'Purge Record?', 'confirm_del': 'Permanently delete staff member: ',
    'cancel': 'CANCEL', 'delete': 'PURGE', 'schedule_for': 'Schedule Day ', 'swaps': 'PENDING SWAPS', 'approve': 'APPROVE', 'reject': 'REJECT',
    'add_emp': 'REGISTER STAFF', 'role': 'Role', 'save_cloud': 'SAVE TO CLOUD', 'directory': 'Directory', 'roster': 'Master Roster', 'no_shifts': 'No active shifts.'
  },
  'de': {
    'gateway': 'Enterprise Cloud-Gateway', 'workspace': 'Arbeitsbereich-ID', 'connect': 'MIT CLOUD-KNOTEN VERBINDEN',
    'portal': 'Identitätsportal', 'user': 'Benutzername', 'pass': 'Passwort', 'auth': 'ZUGRIFF AUTORISIEREN',
    'shift_graph': 'Schichtdiagramm', 'calendar': 'Kalender', 'vacation': 'Urlaub', 'my_shifts': 'MEINE ANSTEHENDEN SCHICHTEN',
    'austria_time': 'Österreichische Ortszeit', 'req_vacation': 'Urlaub beantragen', 'self_schedule': 'Schicht eintragen',
    'pending': 'Ausstehend', 'approved': 'Genehmigt',
    // --- NEW FEATURES DICTIONARY ---
    'conflict_title': 'SCHICHTKONFLIKT', 'conflict_desc': 'Es existiert bereits eine Schicht am Tag ', 'dismiss': 'SCHLIESSEN',
    'morning': 'Morgen (06:00 - 14:00)', 'afternoon': 'Nachmittag (14:00 - 22:00)', 'night': 'Nacht (22:00 - 06:00)',
    'duration': 'Dauer (Stunden)', 'deploy_shift': 'SCHICHT ZUWEISEN', 'monthly_hours': 'MONATSSTUNDEN',
    'overtime': 'ÜBERSTUNDENWARNUNG', 'request_swap': 'Tausch anfragen', 'select_colleague': 'Kollegen auswählen',
    'notifications': 'SYSTEMWARNUNGEN', 'delete_emp': 'Akte löschen?', 'confirm_del': 'Mitarbeiter endgültig löschen: ',
    'cancel': 'ABBRECHEN', 'delete': 'LÖSCHEN', 'schedule_for': 'Planen für Tag ', 'swaps': 'AUSSTEHENDE TAUSCHANFRAGEN', 'approve': 'GENEHMIGEN', 'reject': 'ABLEHNEN',
    'add_emp': 'MITARBEITER REGISTRIEREN', 'role': 'Rolle', 'save_cloud': 'IN CLOUD SPEICHERN', 'directory': 'Verzeichnis', 'roster': 'Dienstplan', 'no_shifts': 'Keine aktiven Schichten.'
  }
};

String t(String key) => dict[appLang.value]?[key] ?? key;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ShiftFlowApp());
}

class ShiftFlowApp extends StatelessWidget {
  const ShiftFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, lang, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ShiftFlow Enterprise',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF090A0F),
            fontFamily: 'Roboto',
            colorScheme: const ColorScheme.dark(primary: Color(0xFF00E5FF), secondary: Color(0xFF8A2BE2), surface: Color(0xFF13161F)),
          ),
          home: const AuthGate(),
        );
      }
    );
  }
}

// ==========================================
// CLOUD DATA MODELS
// ==========================================
class RestaurantTenant {
  String id; String name; String adminPassword;
  RestaurantTenant({required this.id, required this.name, required this.adminPassword});
}

class EmployeeData {
  String id; String restaurantId; String name; String role; String username; String password;
  EmployeeData({required this.id, required this.restaurantId, required this.name, required this.role, required this.username, required this.password});
  factory EmployeeData.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return EmployeeData(id: doc.id, restaurantId: data['restaurantId'] ?? '', name: data['name'] ?? '', role: data['role'] ?? '', username: data['username'] ?? '', password: data['password'] ?? '');
  }
}

class ShiftData {
  String id; String restaurantId; String employeeId; String employeeName; String timeWindow; int dayOfMonth; int durationHours;
  ShiftData({required this.id, required this.restaurantId, required this.employeeId, required this.employeeName, required this.timeWindow, required this.dayOfMonth, this.durationHours = 8});
  factory ShiftData.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ShiftData(id: doc.id, restaurantId: data['restaurantId'] ?? '', employeeId: data['employeeId'] ?? '', employeeName: data['employeeName'] ?? '', timeWindow: data['timeWindow'] ?? '', dayOfMonth: data['dayOfMonth'] ?? 1, durationHours: data['durationHours'] ?? 8);
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

// ==========================================
// SHARED UI COMPONENTS & HELPERS
// ==========================================
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: () => appLang.value = 'en', child: Text('EN', style: TextStyle(color: appLang.value == 'en' ? const Color(0xFF00E5FF) : Colors.white38, fontWeight: FontWeight.bold))),
        const Text('|', style: TextStyle(color: Colors.white38)),
        TextButton(onPressed: () => appLang.value = 'de', child: Text('DE', style: TextStyle(color: appLang.value == 'de' ? const Color(0xFF00E5FF) : Colors.white38, fontWeight: FontWeight.bold))),
      ],
    );
  }
}

Widget _buildNeonTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
  return Container(decoration: BoxDecoration(color: const Color(0xFF13161F), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.1)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))]), child: TextField(controller: controller, obscureText: isPassword, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), prefixIcon: Icon(icon, color: const Color(0xFF00E5FF)))));
}

Widget _buildNeonButton(String text, VoidCallback onTap) {
  return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF8A2BE2)]), boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))]), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2))));
}

// Feature 1: Smart Shift Conflict Engine 
Future<bool> checkShiftConflict(BuildContext context, List<ShiftData> existingShifts, String employeeId, int dayOfMonth) async {
  bool hasConflict = existingShifts.any((s) => s.employeeId == employeeId && s.dayOfMonth == dayOfMonth);
  if (hasConflict) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13161F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent)),
        title: Text(t('conflict_title'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900)),
        content: Text('${t('conflict_desc')}$dayOfMonth.', style: const TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('dismiss'), style: const TextStyle(color: Colors.redAccent)))],
      )
    );
    return false;
  }
  return true;
}

// Feature 6: In-App Notification Center Drawer
Widget buildNotificationDrawer(BuildContext context, String restaurantId) {
  return Drawer(
    backgroundColor: const Color(0xFF090A0F),
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.all(24.0), child: Text(t('notifications'), style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5))),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).collection('notifications').orderBy('time', descending: true).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
                if (snap.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(24), child: Text('No alerts.', style: TextStyle(color: Colors.white54)));
                return ListView.builder(
                  itemCount: snap.data!.docs.length,
                  itemBuilder: (context, i) {
                    var n = snap.data!.docs[i];
                    bool isRead = n['read'] ?? false;
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: isRead ? Colors.white12 : const Color(0xFF00E5FF).withValues(alpha: 0.2), radius: 6, child: isRead ? null : const SizedBox(width: 6, height: 6)),
                      title: Text(n['msg'], style: TextStyle(color: isRead ? Colors.white54 : Colors.white, fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                      onTap: () => n.reference.update({'read': true}),
                    );
                  }
                );
              }
            ),
          )
        ],
      ),
    ),
  );
}

class WorkspaceGateScreen extends StatelessWidget {
  final Function(String) onVerify;
  WorkspaceGateScreen({super.key, required this.onVerify});
  final _workspaceCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LanguageToggle(),
              const Spacer(),
              ShaderMask(shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF8A2BE2)]).createShader(bounds), child: const Icon(Icons.waves_rounded, size: 64, color: Colors.white)),
              const SizedBox(height: 24),
              const Text('ShiftFlow', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1)),
              Text(t('gateway'), style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              const SizedBox(height: 48),
              _buildNeonTextField(controller: _workspaceCtrl, hint: t('workspace'), icon: Icons.hub_outlined),
              const SizedBox(height: 32),
              _buildNeonButton(t('connect'), () => onVerify(_workspaceCtrl.text.trim())),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  final String restaurantName; final Function(String, String) onLogin; final VoidCallback onBack;
  LoginScreen({super.key, required this.restaurantName, required this.onLogin, required this.onBack});
  final _userCtrl = TextEditingController(); final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF00E5FF)), onPressed: onBack)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LanguageToggle(),
              Text(restaurantName.toUpperCase(), style: const TextStyle(color: Color(0xFF8A2BE2), fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
              Text(t('portal'), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
              const SizedBox(height: 48),
              _buildNeonTextField(controller: _userCtrl, hint: t('user'), icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildNeonTextField(controller: _passCtrl, hint: t('pass'), icon: Icons.lock_outline, isPassword: true),
              const SizedBox(height: 40),
              _buildNeonButton(t('auth'), () => onLogin(_userCtrl.text, _passCtrl.text)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// SUPER ADMIN (FOUNDER GOD MODE)
// ==========================================
class SuperAdminShell extends StatelessWidget {
  final VoidCallback onLogout;
  const SuperAdminShell({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF090A0F),
        title: const Text('FOUNDER TERMINAL', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [IconButton(icon: const Icon(Icons.power_settings_new, color: Colors.white54), onPressed: onLogout)],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('restaurants').get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          final clients = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: const Color(0xFF13161F), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3))),
                child: ExpansionTile(
                  title: Text(client['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('ID: ${client.id} | Admin Pass: ${client['adminPassword']}', style: const TextStyle(color: Colors.white54)),
                  iconColor: Colors.redAccent, collapsedIconColor: Colors.redAccent,
                  children: [
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('restaurants').doc(client.id).collection('employees').get(),
                      builder: (ctx, empSnap) {
                        if (!empSnap.hasData) return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
                        return Column(
                          children: empSnap.data!.docs.map((doc) => ListTile(
                            leading: const Icon(Icons.person, color: Colors.white38),
                            title: Text(doc['name'], style: const TextStyle(color: Colors.white)),
                            subtitle: Text('User: ${doc['username']} | Pass: ${doc['password']}', style: const TextStyle(color: Color(0xFF00E5FF), fontFamily: 'monospace')),
                          )).toList(),
                        );
                      }
                    )
                  ],
                ),
              );
            },
          );
        }
      ),
    );
  }
}

// ==========================================
// MANAGER SHELL 
// ==========================================
class AdminShell extends StatefulWidget {
  final String restaurantName; final String workspaceId; final VoidCallback onLogout; final List<EmployeeData> employees; final List<ShiftData> shifts; final List<VacationData> vacations;
  const AdminShell({super.key, required this.restaurantName, required this.workspaceId, required this.onLogout, required this.employees, required this.shifts, required this.vacations});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [_buildStaffTab(), _buildRosterTab()];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF090A0F), elevation: 0,
        title: Text('MANAGER: ${widget.restaurantName}', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 14, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(icon: const Badge(backgroundColor: Color(0xFF00E5FF), child: Icon(Icons.notifications_none, color: Colors.white54)), onPressed: () => Scaffold.of(context).openEndDrawer()),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white54), onPressed: widget.onLogout)
        ]
      ),
      endDrawer: buildNotificationDrawer(context, widget.workspaceId),
      body: screens[_tabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex, onTap: (i) => setState(() => _tabIndex = i),
        backgroundColor: const Color(0xFF090A0F), selectedItemColor: const Color(0xFF00E5FF), unselectedItemColor: Colors.white38,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.groups_2), label: t('directory')),
          BottomNavigationBarItem(icon: const Icon(Icons.calendar_view_week), label: t('roster')),
        ],
      ),
    );
  }

  // Feature 8: Employee Management Panel
  Widget _buildStaffTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(t('directory'), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          IconButton(icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF00E5FF)), onPressed: () => _showAddEmpForm(context))
        ]),
        const SizedBox(height: 24),
        ...widget.employees.map((emp) => Container(
          margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFF13161F), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(emp.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('${emp.role}\nID: ${emp.username}', style: const TextStyle(color: Colors.white54)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Feature 3: Admin Shift Builder Access
                IconButton(icon: const Icon(Icons.add_task, color: Color(0xFF00E5FF)), onPressed: () => _showAdminShiftBuilder(context, emp)),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () {
                  showDialog(context: context, builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF13161F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent)),
                    title: Text(t('delete_emp'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    content: Text('${t('confirm_del')}${emp.name}?', style: const TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'), style: const TextStyle(color: Colors.white54))),
                      TextButton(onPressed: () { 
                        FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).collection('employees').doc(emp.id).delete();
                        Navigator.pop(ctx); 
                      }, child: Text(t('delete'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)))
                    ]
                  ));
                })
              ],
            ),
          ),
        )),
      ],
    );
  }

  void _showAddEmpForm(BuildContext context) {
    final nameCtrl = TextEditingController(); final roleCtrl = TextEditingController(); final userCtrl = TextEditingController(); final passCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF13161F), builder: (context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(t('add_emp'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 24), _buildNeonTextField(controller: nameCtrl, hint: 'Name', icon: Icons.badge_outlined), const SizedBox(height: 12), _buildNeonTextField(controller: roleCtrl, hint: t('role'), icon: Icons.work_outline), const SizedBox(height: 12), _buildNeonTextField(controller: userCtrl, hint: t('user'), icon: Icons.alternate_email), const SizedBox(height: 12), _buildNeonTextField(controller: passCtrl, hint: t('pass'), icon: Icons.lock_outline), const SizedBox(height: 24), _buildNeonButton(t('save_cloud'), () { if (nameCtrl.text.isNotEmpty && userCtrl.text.isNotEmpty) { FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).collection('employees').add({'restaurantId': widget.workspaceId, 'name': nameCtrl.text, 'role': roleCtrl.text.isEmpty ? 'Staff' : roleCtrl.text, 'username': userCtrl.text.toLowerCase(), 'password': passCtrl.text}); Navigator.pop(context); } }), const SizedBox(height: 40)])));
  }

  // Feature 3: Admin Shift Builder
  void _showAdminShiftBuilder(BuildContext context, EmployeeData emp) {
    final dayCtrl = TextEditingController(); final durCtrl = TextEditingController(text: '8');
    String selectedSlot = t('morning');
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF13161F), builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('${t('deploy_shift')}: ${emp.name}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 24), _buildNeonTextField(controller: dayCtrl, hint: 'Day of Month (1-31)', icon: Icons.calendar_today), const SizedBox(height: 12), DropdownButtonFormField<String>(value: selectedSlot, dropdownColor: const Color(0xFF13161F), style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: const Color(0xFF090A0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: [t('morning'), t('afternoon'), t('night')].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) { if(val != null) setModalState(() => selectedSlot = val); }), const SizedBox(height: 12), _buildNeonTextField(controller: durCtrl, hint: t('duration'), icon: Icons.timer), const SizedBox(height: 24), _buildNeonButton(t('deploy_shift'), () async { int day = int.tryParse(dayCtrl.text) ?? 1; if (await checkShiftConflict(ctx, widget.shifts, emp.id, day)) { FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).collection('shifts').add({'restaurantId': widget.workspaceId, 'employeeId': emp.id, 'employeeName': emp.name, 'timeWindow': selectedSlot, 'dayOfMonth': day, 'durationHours': int.tryParse(durCtrl.text) ?? 8}); Navigator.pop(ctx); } }), const SizedBox(height: 40)]))));
  }

  Widget _buildRosterTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Feature 5: Admin Shift Swap Approvals
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).collection('swapRequests').where('status', isEqualTo: 'pending').snapshots(),
          builder: (context, swapSnap) {
            if (!swapSnap.hasData || swapSnap.data!.docs.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('swaps'), style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                ...swapSnap.data!.docs.map((doc) => Container(
                  margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF13161F), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withValues(alpha: 0.5))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${doc['requesterName']} wants to assign shift to ${doc['targetName']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _buildNeonButton(t('approve'), () async {
                        WriteBatch batch = FirebaseFirestore.instance.batch();
                        batch.update(doc.reference, {'status': 'approved'});
                        batch.update(FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).collection('shifts').doc(doc['shiftId']), {'employeeId': doc['targetId'], 'employeeName': doc['targetName']});
                        batch.set(FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).collection('notifications').doc(), {'msg': 'Swap approved for ${doc['requesterName']}', 'read': false, 'time': DateTime.now().toIso8601String()});
                        await batch.commit();
                      })),
                      const SizedBox(width: 8),
                      Expanded(child: TextButton(onPressed: () => doc.reference.update({'status': 'rejected'}), child: Text(t('reject'), style: const TextStyle(color: Colors.redAccent))))
                    ])
                  ])
                )),
                const SizedBox(height: 24),
              ],
            );
          }
        ),
        Text(t('roster'), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 24),
        if (widget.shifts.isEmpty) Text(t('no_shifts'), style: const TextStyle(color: Colors.white54)),
        ...widget.shifts.map((shift) => Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFF13161F), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))), child: ListTile(title: Text(shift.employeeName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text('${shift.timeWindow} • Day: ${shift.dayOfMonth}', style: const TextStyle(color: Color(0xFF00E5FF))), trailing: IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent), onPressed: () => FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).collection('shifts').doc(shift.id).delete())))),
      ],
    );
  }
}

// ==========================================
// EMPLOYEE PLATFORM (GRAPH, CALENDAR, VACATION)
// ==========================================
class EmployeeShell extends StatefulWidget {
  final String restaurantName; final VoidCallback onLogout; final EmployeeData currentEmployee; final List<ShiftData> allShifts; final List<VacationData> vacations; final List<EmployeeData> allEmployees;
  const EmployeeShell({super.key, required this.restaurantName, required this.onLogout, required this.currentEmployee, required this.allShifts, required this.vacations, required this.allEmployees});
  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  int _tabIndex = 0;
  Timer? _clockTimer;
  String _currentTimeStr = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  // Feature 2: Real-Time Auto-Switching CET/CEST Clock
  void _updateTime() {
    final now = DateTime.now().toUtc();
    bool isSummerTime = _isCEST(now);
    final austriaTime = now.add(Duration(hours: isSummerTime ? 2 : 1));
    if (mounted) {
      setState(() {
        _currentTimeStr = "${austriaTime.hour.toString().padLeft(2, '0')}:${austriaTime.minute.toString().padLeft(2, '0')}:${austriaTime.second.toString().padLeft(2, '0')} ${isSummerTime ? 'CEST' : 'CET'}";
      });
    }
  }

  bool _isCEST(DateTime utcNow) {
    if (utcNow.month > 3 && utcNow.month < 10) return true;
    if (utcNow.month < 3 || utcNow.month > 10) return false;
    int previousSunday(int y, int m, int d) => d - DateTime.utc(y, m, d).weekday;
    if (utcNow.month == 3) return utcNow.day >= previousSunday(utcNow.year, 3, 31) && (utcNow.day > previousSunday(utcNow.year, 3, 31) || utcNow.hour >= 1);
    return utcNow.day < previousSunday(utcNow.year, 10, 31) || (utcNow.day == previousSunday(utcNow.year, 10, 31) && utcNow.hour < 1);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [_buildGraphView(), _buildCalendarView(), _buildVacationView()];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF090A0F), elevation: 0,
        title: Text(widget.restaurantName.toUpperCase(), style: const TextStyle(color: Color(0xFF8A2BE2), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        actions: [
          // Feature 6 Trigger: Notification Bell
          IconButton(icon: const Badge(backgroundColor: Color(0xFF00E5FF), child: Icon(Icons.notifications_none, color: Colors.white54)), onPressed: () => Scaffold.of(context).openEndDrawer()),
          IconButton(icon: const Icon(Icons.power_settings_new, color: Colors.white54), onPressed: widget.onLogout)
        ]
      ),
      endDrawer: buildNotificationDrawer(context, widget.currentEmployee.restaurantId),
      body: SafeArea(child: screens[_tabIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex, onTap: (i) => setState(() => _tabIndex = i),
        backgroundColor: const Color(0xFF090A0F), selectedItemColor: const Color(0xFF00E5FF), unselectedItemColor: Colors.white38,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.bar_chart), label: t('shift_graph')),
          BottomNavigationBarItem(icon: const Icon(Icons.calendar_month), label: t('calendar')),
          BottomNavigationBarItem(icon: const Icon(Icons.beach_access), label: t('vacation')),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.currentEmployee.name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFF8A2BE2).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF8A2BE2))),
          child: Text('${t('austria_time')} - $_currentTimeStr', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildGraphView() {
    final myShifts = widget.allShifts.where((s) => s.employeeId == widget.currentEmployee.id).toList();
    
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildTopHeader(),
        // Feature 4: Hours Tracker
        Builder(builder: (context) {
          int totalHours = myShifts.fold(0, (sum, shift) => sum + shift.durationHours);
          bool isOvertime = totalHours > 160;
          double progress = (totalHours / 160).clamp(0.0, 1.0);
          
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF13161F), borderRadius: BorderRadius.circular(20), border: Border.all(color: isOvertime ? Colors.redAccent : Colors.white.withValues(alpha: 0.05))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t('monthly_hours'), style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
                    if (isOvertime) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)), child: Text(t('overtime'), style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 12),
                Text('$totalHours / 160h', style: TextStyle(color: isOvertime ? Colors.redAccent : Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress, backgroundColor: Colors.white.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation<Color>(isOvertime ? Colors.purpleAccent : const Color(0xFF00E5FF)), minHeight: 8, borderRadius: BorderRadius.circular(4)),
              ],
            ),
          );
        }),
        const SizedBox(height: 32),
        Text(t('my_shifts'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white54)),
        const SizedBox(height: 16),
        ...myShifts.map((shift) => InkWell(
          onTap: () {
            // Feature 5: Shift Swap Request System
            String targetEmpId = widget.allEmployees.firstWhere((e) => e.id != widget.currentEmployee.id, orElse: () => widget.currentEmployee).id;
            showModalBottomSheet(context: context, backgroundColor: const Color(0xFF13161F), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(t('request_swap'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 24), DropdownButtonFormField<String>(value: targetEmpId, dropdownColor: const Color(0xFF13161F), style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: const Color(0xFF090A0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: widget.allEmployees.where((e) => e.id != widget.currentEmployee.id).map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(), onChanged: (val) { if(val != null) setModalState(() => targetEmpId = val); }), const SizedBox(height: 24), _buildNeonButton(t('request_swap'), () { final tEmp = widget.allEmployees.firstWhere((e) => e.id == targetEmpId); FirebaseFirestore.instance.collection('restaurants').doc(widget.currentEmployee.restaurantId).collection('swapRequests').add({'requesterId': widget.currentEmployee.id, 'requesterName': widget.currentEmployee.name, 'targetId': tEmp.id, 'targetName': tEmp.name, 'shiftId': shift.id, 'status': 'pending'}); Navigator.pop(ctx); })]))));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFF13161F), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
            child: ListTile(
              leading: const Icon(Icons.swap_calls, color: Color(0xFF00E5FF)),
              title: Text('${shift.timeWindow} (Day ${shift.dayOfMonth})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('Tap to request swap', style: const TextStyle(color: Colors.white54)),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildCalendarView() {
    final myShifts = widget.allShifts.where((s) => s.employeeId == widget.currentEmployee.id).toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildTopHeader(),
        Text(t('calendar').toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white54)),
        const SizedBox(height: 24),
        // Feature 9: Tappable Self-Schedule Grid
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: 31,
          itemBuilder: (context, index) {
            int day = index + 1;
            bool hasShift = myShifts.any((s) => s.dayOfMonth == day);
            return InkWell(
              onTap: () {
                String selectedSlot = t('morning');
                showModalBottomSheet(
                  context: context, backgroundColor: const Color(0xFF13161F), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (ctx) => StatefulBuilder(
                    builder: (ctx, setModalState) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${t('schedule_for')}$day', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 24),
                          DropdownButtonFormField<String>(
                            value: selectedSlot, dropdownColor: const Color(0xFF13161F), style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(filled: true, fillColor: const Color(0xFF090A0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                            items: [t('morning'), t('afternoon'), t('night')].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (val) { if(val != null) setModalState(() => selectedSlot = val); },
                          ),
                          const SizedBox(height: 24),
                          _buildNeonButton(t('deploy_shift'), () async {
                            Navigator.pop(ctx);
                            if (await checkShiftConflict(context, widget.allShifts, widget.currentEmployee.id, day)) {
                              FirebaseFirestore.instance.collection('restaurants').doc(widget.currentEmployee.restaurantId).collection('shifts').add({
                                'restaurantId': widget.currentEmployee.restaurantId, 'employeeId': widget.currentEmployee.id, 'employeeName': widget.currentEmployee.name, 'timeWindow': selectedSlot, 'dayOfMonth': day, 'durationHours': 8
                              });
                            }
                          })
                        ],
                      ),
                    )
                  )
                );
              },
              child: Container(
                decoration: BoxDecoration(color: hasShift ? const Color(0xFF8A2BE2).withValues(alpha: 0.3) : const Color(0xFF13161F), borderRadius: BorderRadius.circular(8), border: Border.all(color: hasShift ? const Color(0xFF8A2BE2) : Colors.white.withValues(alpha: 0.05))),
                child: Center(child: Text('$day', style: TextStyle(color: hasShift ? Colors.white : Colors.white54, fontWeight: FontWeight.bold))),
              ),
            );
          },
        )
      ],
    );
  }

  Widget _buildVacationView() {
    final myVacations = widget.vacations.where((v) => v.employeeName == widget.currentEmployee.name).toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildTopHeader(),
        Text(t('vacation').toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white54)),
        const SizedBox(height: 24),
        // Feature 7: Real Vacation Date Picker
        _buildNeonButton(t('req_vacation'), () async {
          final DateTimeRange? picked = await showDateRangePicker(
            context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
            builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF00E5FF), surface: Color(0xFF13161F), onSurface: Colors.white)), child: child!),
          );
          if (picked != null) {
            String dates = "${picked.start.day}/${picked.start.month} - ${picked.end.day}/${picked.end.month}";
            FirebaseFirestore.instance.collection('restaurants').doc(widget.currentEmployee.restaurantId).collection('vacations').add({
              'restaurantId': widget.currentEmployee.restaurantId, 'employeeName': widget.currentEmployee.name, 'dates': dates, 'status': 'Pending'
            });
          }
        }),
        const SizedBox(height: 24),
        ...myVacations.map((vac) => Container(
          margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFF13161F), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: ListTile(title: Text(vac.dates, style: const TextStyle(color: Colors.white)), trailing: Text(t(vac.status.toLowerCase()), style: TextStyle(color: vac.status == 'Pending' ? Colors.orange : Colors.green, fontWeight: FontWeight.bold))),
        )),
      ],
    );
  }
}