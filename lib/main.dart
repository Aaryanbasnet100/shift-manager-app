import 'package:flutter/material.dart';

void main() {
  runApp(const ShiftManagerApp());
}

class ShiftManagerApp extends StatelessWidget {
  const ShiftManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Enterprise Shift Engine',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FA),
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF141927),
          primary: const Color(0xFF141927),
          secondary: const Color(0xFFC7A97A),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// ==========================================
// CENTRAL DATA MODELS
// ==========================================
class EmployeeData {
  String name;
  String role;
  String username;
  String password;
  bool isClockedIn;

  EmployeeData({
    required this.name,
    required this.role,
    required this.username,
    required this.password,
    this.isClockedIn = false,
  });
}

class ShiftData {
  String employeeName;
  String role;
  String timeWindow;
  String day; 

  ShiftData({
    required this.employeeName,
    required this.role,
    required this.timeWindow,
    required this.day,
  });
}

// ==========================================
// 1. THE AUTHENTICATION GATE & CENTRAL STATE
// ==========================================
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoggedIn = false;
  String _currentLoggedInUsername = '';
  String _userRole = ''; 
  
  // App Global Configurations & Memory
  String _adminPassword = 'admin123';

  // Live Lists stored in memory
  final List<EmployeeData> _employees = [
    EmployeeData(name: 'Elena Valdes', role: 'Shift Lead', username: 'elena', password: 'crew123', isClockedIn: true),
    EmployeeData(name: 'Marcus Thorne', role: 'Drive-Thru', username: 'marcus', password: 'crew123', isClockedIn: true),
    EmployeeData(name: 'Sarah Jenkins', role: 'Assembly Line', username: 'sarah', password: 'crew123'),
  ];

  final List<ShiftData> _shifts = [
    ShiftData(employeeName: 'Elena Valdes', role: 'Front Register', timeWindow: '14:00 - 22:00', day: 'Tue'),
    ShiftData(employeeName: 'Marcus Thorne', role: 'Drive-Thru', timeWindow: '15:00 - 23:00', day: 'Tue'),
    ShiftData(employeeName: 'Sarah Jenkins', role: 'Assembly Line', timeWindow: '16:00 - 00:00', day: 'Tue'),
  ];

  void _login(String username, String password) {
    if (username.toLowerCase() == 'admin' && password == _adminPassword) {
      setState(() {
        _userRole = 'admin';
        _currentLoggedInUsername = 'admin';
        _isLoggedIn = true;
      });
    } else {
      EmployeeData? matchedEmployee;
      for (var emp in _employees) {
        if (emp.username == username.toLowerCase() && emp.password == password) {
          matchedEmployee = emp;
          break;
        }
      }

      if (matchedEmployee != null) {
        setState(() {
          _userRole = 'employee';
          _currentLoggedInUsername = matchedEmployee!.username;
          _isLoggedIn = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid Credentials. Admin password is currently: $_adminPassword'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
      _userRole = '';
      _currentLoggedInUsername = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen(onLogin: _login);
    }

    if (_userRole == 'admin') {
      return AdminShell(
        onLogout: _logout,
        employees: _employees,
        shifts: _shifts,
        adminPassword: _adminPassword,
        onAddEmployee: (newEmp) => setState(() => _employees.add(newEmp)),
        onAddShift: (newShift) => setState(() => _shifts.add(newShift)),
        onChangeAdminPassword: (newPass) => setState(() => _adminPassword = newPass),
      );
    } else {
      final currentEmp = _employees.firstWhere((e) => e.username == _currentLoggedInUsername);
      return EmployeeShell(
        onLogout: _logout,
        currentEmployee: currentEmp,
        allShifts: _shifts,
        onClockToggle: () => setState(() => currentEmp.isClockedIn = !currentEmp.isClockedIn),
      );
    }
  }
}

// LOGIN SCREEN UI
class LoginScreen extends StatefulWidget {
  final Function(String, String) onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141927),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFC7A97A).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.lock_person_rounded, color: Color(0xFFC7A97A), size: 40),
              ),
              const SizedBox(height: 24),
              const Text('System Access', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Enter admin or employee username.', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 48),
              TextField(
                controller: _userController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  hintText: 'Username',
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  hintText: 'Password',
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => widget.onLogin(_userController.text, _passController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC7A97A),
                  foregroundColor: const Color(0xFF141927),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Authenticate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. REAL-TIME ADMIN PANEL
// ==========================================
class AdminShell extends StatefulWidget {
  final VoidCallback onLogout;
  final List<EmployeeData> employees;
  final List<ShiftData> shifts;
  final String adminPassword;
  final Function(EmployeeData) onAddEmployee;
  final Function(ShiftData) onAddShift;
  final Function(String) onChangeAdminPassword;

  const AdminShell({
    super.key,
    required this.onLogout,
    required this.employees,
    required this.shifts,
    required this.adminPassword,
    required this.onAddEmployee,
    required this.onAddShift,
    required this.onChangeAdminPassword,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      AdminDashboard(shifts: widget.shifts, employees: widget.employees),
      AdminTeamScreen(employees: widget.employees, onAddEmployee: widget.onAddEmployee),
      AdminShiftScreen(shifts: widget.shifts, employees: widget.employees, onAddShift: widget.onAddShift),
      AdminSettingsScreen(adminPassword: widget.adminPassword, onChangePassword: widget.onChangeAdminPassword, onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _currentIndex, children: screens)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF141927),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Staff'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Shifts'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Config'),
        ],
      ),
    );
  }
}

// ADMIN DASHBOARD
class AdminDashboard extends StatelessWidget {
  final List<ShiftData> shifts;
  final List<EmployeeData> employees;
  const AdminDashboard({super.key, required this.shifts, required this.employees});

  @override
  Widget build(BuildContext context) {
    int clockedInCount = employees.where((e) => e.isClockedIn).length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Control Panel', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF141927))),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Active Now', '$clockedInCount / ${employees.length}', Colors.green.shade50, Colors.green)),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard('Total Shifts', '${shifts.length}', Colors.blue.shade50, Colors.blue)),
          ],
        ),
        const SizedBox(height: 32),
        const Text('CURRENT OPERATIONAL ROSTER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: shifts.map((shift) {
              final emp = employees.firstWhere((e) => e.name == shift.employeeName, orElse: () => EmployeeData(name: '', role: '', username: '', password: ''));
              return ListTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFF141927), child: Text(shift.employeeName[0], style: const TextStyle(color: Colors.white))),
                title: Text(shift.employeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${shift.role} • Day: ${shift.day}'),
                trailing: Chip(
                  label: Text(emp.isClockedIn ? 'Clocked In' : 'Scheduled', style: TextStyle(fontSize: 11, color: emp.isClockedIn ? Colors.green : Colors.orange)),
                  backgroundColor: emp.isClockedIn ? Colors.green.shade50 : Colors.orange.shade50,
                  side: BorderSide.none,
                ),
              );
            }).toList(),
          ),
        )
      ],
    );
  }

  Widget _buildMetricCard(String title, String val, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text(val, style: TextStyle(color: const Color(0xFF141927), fontSize: 28, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

// ADMIN STAFF CONFIGURATION
class AdminTeamScreen extends StatelessWidget {
  final List<EmployeeData> employees;
  final Function(EmployeeData) onAddEmployee;
  const AdminTeamScreen({super.key, required this.employees, required this.onAddEmployee});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Staff Registry', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          ...employees.map((emp) => Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Role: ${emp.role}\nUser: ${emp.username} | Pass: ${emp.password}'),
              isThreeLine: true,
              trailing: Icon(Icons.verified_user_outlined, color: Theme.of(context).colorScheme.secondary),
            ),
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateStaffModal(context);
        },
        backgroundColor: const Color(0xFF141927),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Employee', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showCreateStaffModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Create Employee Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Role (e.g. Kitchen, Front Counter)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Login Username', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Account Password', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if(nameCtrl.text.isNotEmpty && userCtrl.text.isNotEmpty) {
                  onAddEmployee(EmployeeData(
                    name: nameCtrl.text,
                    role: roleCtrl.text,
                    username: userCtrl.text.trim().toLowerCase(),
                    password: passCtrl.text,
                  ));
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFFC7A97A)),
              child: const Text('Save Worker to System', style: TextStyle(color: Color(0xFF141927), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ADMIN SHIFT MANAGEMENT
class AdminShiftScreen extends StatelessWidget {
  final List<ShiftData> shifts;
  final List<EmployeeData> employees;
  final Function(ShiftData) onAddShift;
  const AdminShiftScreen({super.key, required this.shifts, required this.employees, required this.onAddShift});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Shift Allocations', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          ...shifts.map((shift) => Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.access_time, color: Color(0xFF141927)),
              title: Text(shift.employeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${shift.role} • ${shift.timeWindow}'),
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF141927), borderRadius: BorderRadius.circular(8)),
                child: Text(shift.day, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateShiftModal(context),
        backgroundColor: const Color(0xFF141927),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Deploy New Shift', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showCreateShiftModal(BuildContext context) {
    String chosenEmployee = employees.isNotEmpty ? employees.first.name : '';
    final timeCtrl = TextEditingController(text: '14:00 - 22:00');
    final dayCtrl = TextEditingController(text: 'Wed');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Schedule a Shift', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Select Target Employee:', style: TextStyle(fontWeight: FontWeight.w600)),
              DropdownButton<String>(
                value: chosenEmployee,
                isExpanded: true,
                items: employees.map((e) => DropdownMenuItem(value: e.name, child: Text(e.name))).toList(),
                onChanged: (val) {
                  if(val != null) setModalState(() => chosenEmployee = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Time Slot (e.g. 06:00 - 14:00)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: dayCtrl, decoration: const InputDecoration(labelText: 'Day (e.g. Wed, Thu)', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (chosenEmployee.isNotEmpty) {
                    final empObj = employees.firstWhere((e) => e.name == chosenEmployee);
                    onAddShift(ShiftData(
                      employeeName: chosenEmployee,
                      role: empObj.role,
                      timeWindow: timeCtrl.text,
                      day: dayCtrl.text,
                    ));
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFFC7A97A)),
                child: const Text('Publish to Roster', style: TextStyle(color: Color(0xFF141927), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ADMIN GLOBAL CONFIGURATION / PASSWORD CHANGING
class AdminSettingsScreen extends StatelessWidget {
  final String adminPassword;
  final Function(String) onChangePassword;
  final VoidCallback onLogout;

  const AdminSettingsScreen({super.key, required this.adminPassword, required this.onChangePassword, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final passCtrl = TextEditingController(text: adminPassword);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('System Configuration', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Modify Master Admin Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Changing this updates the main access key instantly.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'New Master Password'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  onChangePassword(passCtrl.text);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin password updated successfully!')));
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF141927), foregroundColor: Colors.white),
                child: const Text('Update Master Key'),
              )
            ],
          ),
        ),
        const SizedBox(height: 40),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label: const Text('Exit System Console', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56), side: const BorderSide(color: Colors.redAccent)),
        )
      ],
    );
  }
}

// ==========================================
// 3. EMPLOYEE TERMINAL PANEL
// ==========================================
class EmployeeShell extends StatelessWidget {
  final VoidCallback onLogout;
  final EmployeeData currentEmployee;
  final List<ShiftData> allShifts;
  final VoidCallback onClockToggle;

  const EmployeeShell({
    super.key,
    required this.onLogout,
    required this.currentEmployee,
    required this.allShifts,
    required this.onClockToggle,
  });

  @override
  Widget build(BuildContext context) {
    final myShifts = allShifts.where((s) => s.employeeName == currentEmployee.name).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CREW TERMINAL', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
                    Text(currentEmployee.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF141927))),
                    Text('Assigned Role: ${currentEmployee.role}', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.logout, color: Colors.blueGrey), onPressed: onLogout)
              ],
            ),
            const SizedBox(height: 32),
            
            // TIME CLOCK TERMINAL
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: currentEmployee.isClockedIn ? Colors.green.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: currentEmployee.isClockedIn ? Colors.green.withValues(alpha: 0.3) : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.fingerprint, size: 64, color: currentEmployee.isClockedIn ? Colors.green : const Color(0xFF141927)),
                  const SizedBox(height: 16),
                  Text(
                    currentEmployee.isClockedIn ? 'YOU ARE ON THE CLOCK' : 'YOU ARE NOT WORKING',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: currentEmployee.isClockedIn ? Colors.green.shade900 : const Color(0xFF141927)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: onClockToggle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentEmployee.isClockedIn ? Colors.redAccent : const Color(0xFF141927),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(currentEmployee.isClockedIn ? 'Punch Out' : 'Punch In Now', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text('YOUR DEPLOYED SHIFTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            if (myShifts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No shifts scheduled for you yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
            ...myShifts.map((shift) => Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Color(0xFF141927)),
                title: Text(shift.timeWindow, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(shift.role),
                trailing: Chip(label: Text(shift.day)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}