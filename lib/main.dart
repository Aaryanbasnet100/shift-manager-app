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
  Color avatarColor;

  EmployeeData({
    required this.name,
    required this.role,
    required this.username,
    required this.password,
    required this.avatarColor,
  });
}

class ShiftData {
  String employeeName;
  String role;
  String timeWindow;
  int dayOfMonth; // Simplified for this prototype (1-30)
  Color shiftColor;

  ShiftData({
    required this.employeeName,
    required this.role,
    required this.timeWindow,
    required this.dayOfMonth,
    required this.shiftColor,
  });
}

class ChatMessage {
  String senderName;
  Color senderColor;
  String message;
  String time;

  ChatMessage({
    required this.senderName,
    required this.senderColor,
    required this.message,
    required this.time,
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
  
  String _adminPassword = 'admin123';
  Color _adminAvatarColor = Colors.blueGrey;

  // Initial Mock Data
  final List<EmployeeData> _employees = [
    EmployeeData(name: 'Elena Valdes', role: 'Shift Lead', username: 'elena', password: 'crew123', avatarColor: Colors.blue),
    EmployeeData(name: 'Marcus Thorne', role: 'Drive-Thru', username: 'marcus', password: 'crew123', avatarColor: Colors.orange),
  ];

  final List<ShiftData> _shifts = [
    ShiftData(employeeName: 'Elena Valdes', role: 'Front Register', timeWindow: '14:00 - 22:00', dayOfMonth: 14, shiftColor: Colors.blue),
    ShiftData(employeeName: 'Marcus Thorne', role: 'Drive-Thru', timeWindow: '15:00 - 23:00', dayOfMonth: 15, shiftColor: Colors.orange),
    ShiftData(employeeName: 'Elena Valdes', role: 'Shift Lead', timeWindow: '10:00 - 18:00', dayOfMonth: 16, shiftColor: Colors.green),
  ];

  final List<ChatMessage> _messages = [
    ChatMessage(senderName: 'System', senderColor: Colors.grey, message: 'Welcome to the Breakroom Chat.', time: '08:00 AM'),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Credentials.'), backgroundColor: Colors.redAccent));
      }
    }
  }

  void _logout() => setState(() { _isLoggedIn = false; _userRole = ''; _currentLoggedInUsername = ''; });

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) return LoginScreen(onLogin: _login);

    if (_userRole == 'admin') {
      return AdminShell(
        onLogout: _logout,
        employees: _employees,
        shifts: _shifts,
        messages: _messages,
        adminPassword: _adminPassword,
        adminAvatarColor: _adminAvatarColor,
        onAddEmployee: (e) => setState(() => _employees.add(e)),
        onAddShift: (s) => setState(() => _shifts.add(s)),
        onSendMessage: (m) => setState(() => _messages.add(m)),
        onChangePassword: (p) => setState(() => _adminPassword = p),
        onChangeAvatar: (c) => setState(() => _adminAvatarColor = c),
      );
    } else {
      final currentEmp = _employees.firstWhere((e) => e.username == _currentLoggedInUsername);
      return EmployeeShell(
        onLogout: _logout,
        currentEmployee: currentEmp,
        allShifts: _shifts,
        messages: _messages,
        onSendMessage: (m) => setState(() => _messages.add(m)),
        onUpdatePassword: (p) => setState(() => currentEmp.password = p),
        onUpdateAvatar: (c) => setState(() => currentEmp.avatarColor = c),
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
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFC7A97A).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.lock_person_rounded, color: Color(0xFFC7A97A), size: 40)),
              const SizedBox(height: 24),
              const Text('System Access', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 48),
              TextField(controller: _userController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: Colors.white.withValues(alpha: 0.05), hintText: 'Username', hintStyle: const TextStyle(color: Colors.white38), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              TextField(controller: _passController, obscureText: true, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: Colors.white.withValues(alpha: 0.05), hintText: 'Password', hintStyle: const TextStyle(color: Colors.white38), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => widget.onLogin(_userController.text, _passController.text),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC7A97A), foregroundColor: const Color(0xFF141927), minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
// 2. ADMIN ENVIRONMENT
// ==========================================
class AdminShell extends StatefulWidget {
  final VoidCallback onLogout;
  final List<EmployeeData> employees;
  final List<ShiftData> shifts;
  final List<ChatMessage> messages;
  final String adminPassword;
  final Color adminAvatarColor;
  final Function(EmployeeData) onAddEmployee;
  final Function(ShiftData) onAddShift;
  final Function(ChatMessage) onSendMessage;
  final Function(String) onChangePassword;
  final Function(Color) onChangeAvatar;

  const AdminShell({
    super.key, required this.onLogout, required this.employees, required this.shifts, required this.messages,
    required this.adminPassword, required this.adminAvatarColor, required this.onAddEmployee, required this.onAddShift,
    required this.onSendMessage, required this.onChangePassword, required this.onChangeAvatar,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      AdminDashboard(shifts: widget.shifts, employees: widget.employees),
      AdminTeamScreen(employees: widget.employees, onAddEmployee: widget.onAddEmployee),
      AdminShiftScreen(shifts: widget.shifts, employees: widget.employees, onAddShift: widget.onAddShift),
      ChatFeedScreen(messages: widget.messages, currentUser: 'Admin', avatarColor: widget.adminAvatarColor, onSendMessage: widget.onSendMessage),
      ProfileSettingsScreen(isEmployee: false, currentName: 'Admin', currentPassword: widget.adminPassword, currentAvatar: widget.adminAvatarColor, onUpdatePassword: widget.onChangePassword, onUpdateAvatar: widget.onChangeAvatar, onLogout: widget.onLogout),
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
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Dash'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Staff'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Shifts'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Profile'),
        ],
      ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  final List<ShiftData> shifts;
  final List<EmployeeData> employees;
  const AdminDashboard({super.key, required this.shifts, required this.employees});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Command Center', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF141927), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Deployed Shifts', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${shifts.length}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text('ALL SCHEDULED SHIFTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        ...shifts.map((shift) => Card(
          elevation: 0, color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: shift.shiftColor, radius: 16),
            title: Text(shift.employeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${shift.role} • ${shift.timeWindow}'),
            trailing: Text('Day ${shift.dayOfMonth}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        )),
      ],
    );
  }
}

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
          const SizedBox(height: 8),
          const Text('Monitor active credentials. Passwords are visible for admin overrides.', style: TextStyle(color: Colors.blueGrey)),
          const SizedBox(height: 24),
          ...employees.map((emp) => Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: emp.avatarColor, child: Text(emp.name[0], style: const TextStyle(color: Colors.white))),
              title: Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('User: ${emp.username}\nPass: ${emp.password}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              isThreeLine: true,
            ),
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateStaffModal(context),
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
      context: context, isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Create Employee Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Login Username', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Account Password', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if(nameCtrl.text.isNotEmpty && userCtrl.text.isNotEmpty) {
                  onAddEmployee(EmployeeData(name: nameCtrl.text, role: roleCtrl.text, username: userCtrl.text.toLowerCase(), password: passCtrl.text, avatarColor: Colors.blueGrey));
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFFC7A97A)),
              child: const Text('Save Worker', style: TextStyle(color: Color(0xFF141927), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class AdminShiftScreen extends StatefulWidget {
  final List<ShiftData> shifts;
  final List<EmployeeData> employees;
  final Function(ShiftData) onAddShift;
  const AdminShiftScreen({super.key, required this.shifts, required this.employees, required this.onAddShift});

  @override
  State<AdminShiftScreen> createState() => _AdminShiftScreenState();
}

class _AdminShiftScreenState extends State<AdminShiftScreen> {
  void _showCreateShiftModal(BuildContext context) {
    String chosenEmployee = widget.employees.isNotEmpty ? widget.employees.first.name : '';
    final timeCtrl = TextEditingController(text: '14:00 - 22:00');
    final dayCtrl = TextEditingController(text: '15');
    Color chosenColor = Colors.blue;

    final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.pink];

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Colored Shift', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: chosenEmployee, isExpanded: true,
                items: widget.employees.map((e) => DropdownMenuItem(value: e.name, child: Text(e.name))).toList(),
                onChanged: (val) { if(val != null) setModalState(() => chosenEmployee = val); },
              ),
              const SizedBox(height: 12),
              TextField(controller: dayCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Day of Month (1-30)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Time Slot (e.g. 06:00 - 14:00)', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              const Text('Calendar Color Indicator:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: colors.map((c) => GestureDetector(
                  onTap: () => setModalState(() => chosenColor = c),
                  child: CircleAvatar(backgroundColor: c, radius: 20, child: chosenColor == c ? const Icon(Icons.check, color: Colors.white) : null),
                )).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (chosenEmployee.isNotEmpty) {
                    final empObj = widget.employees.firstWhere((e) => e.name == chosenEmployee);
                    widget.onAddShift(ShiftData(employeeName: chosenEmployee, role: empObj.role, timeWindow: timeCtrl.text, dayOfMonth: int.tryParse(dayCtrl.text) ?? 1, shiftColor: chosenColor));
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFFC7A97A)),
                child: const Text('Publish Shift', style: TextStyle(color: Color(0xFF141927), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Master Calendar Builder', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          // Custom Month Grid Calendar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemCount: 30, // 30 days mock
              itemBuilder: (context, index) {
                int day = index + 1;
                // Find shifts for this day
                List<ShiftData> dayShifts = widget.shifts.where((s) => s.dayOfMonth == day).toList();
                
                return Container(
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$day', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      if (dayShifts.isNotEmpty)
                        Wrap(
                          spacing: 2,
                          children: dayShifts.take(3).map((s) => CircleAvatar(radius: 4, backgroundColor: s.shiftColor)).toList(),
                        )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateShiftModal(context),
        backgroundColor: const Color(0xFF141927),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Shift', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}


// ==========================================
// 3. EMPLOYEE ENVIRONMENT
// ==========================================
class EmployeeShell extends StatefulWidget {
  final VoidCallback onLogout;
  final EmployeeData currentEmployee;
  final List<ShiftData> allShifts;
  final List<ChatMessage> messages;
  final Function(ChatMessage) onSendMessage;
  final Function(String) onUpdatePassword;
  final Function(Color) onUpdateAvatar;

  const EmployeeShell({
    super.key, required this.onLogout, required this.currentEmployee, required this.allShifts, required this.messages,
    required this.onSendMessage, required this.onUpdatePassword, required this.onUpdateAvatar,
  });

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final myShifts = widget.allShifts.where((s) => s.employeeName == widget.currentEmployee.name).toList();

    final screens = [
      EmployeeShiftListScreen(myShifts: myShifts, empName: widget.currentEmployee.name),
      EmployeeCalendarScreen(myShifts: myShifts),
      ChatFeedScreen(messages: widget.messages, currentUser: widget.currentEmployee.name, avatarColor: widget.currentEmployee.avatarColor, onSendMessage: widget.onSendMessage),
      ProfileSettingsScreen(isEmployee: true, currentName: widget.currentEmployee.name, currentPassword: widget.currentEmployee.password, currentAvatar: widget.currentEmployee.avatarColor, onUpdatePassword: widget.onUpdatePassword, onUpdateAvatar: widget.onUpdateAvatar, onLogout: widget.onLogout),
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
          BottomNavigationBarItem(icon: Icon(Icons.view_agenda_outlined), label: 'My Shifts'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Social'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

// EMPLOYEE LIST VIEW ("Bar" View)
// EMPLOYEE LIST VIEW ("Bar" View)
class EmployeeShiftListScreen extends StatelessWidget {
  final List<ShiftData> myShifts;
  final String empName;
  const EmployeeShiftListScreen({super.key, required this.myShifts, required this.empName});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Hello, $empName', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Here is your upcoming schedule in list view.', style: TextStyle(color: Colors.blueGrey)),
        const SizedBox(height: 24),
        if (myShifts.isEmpty) const Text('No shifts scheduled.', style: TextStyle(fontStyle: FontStyle.italic)),
        ...myShifts.map((shift) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(16), 
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
              right: BorderSide(color: Colors.grey.shade200),
              bottom: BorderSide(color: Colors.grey.shade200),
              left: BorderSide(color: shift.shiftColor, width: 6),
            )
          ),
          child: ListTile(
            title: Text('Day ${shift.dayOfMonth}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text(shift.role),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: shift.shiftColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(shift.timeWindow, style: TextStyle(color: shift.shiftColor, fontWeight: FontWeight.bold)),
            ),
          ),
        )),
      ],
    );
  }
}

// EMPLOYEE CALENDAR VIEW
class EmployeeCalendarScreen extends StatelessWidget {
  final List<ShiftData> myShifts;
  const EmployeeCalendarScreen({super.key, required this.myShifts});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('My Calendar', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: 30, 
            itemBuilder: (context, index) {
              int day = index + 1;
              bool hasShift = myShifts.any((s) => s.dayOfMonth == day);
              Color shiftColor = hasShift ? myShifts.firstWhere((s) => s.dayOfMonth == day).shiftColor : Colors.transparent;
              
              return Container(
                decoration: BoxDecoration(color: hasShift ? shiftColor.withValues(alpha: 0.2) : Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: hasShift ? shiftColor : Colors.grey.shade200)),
                child: Center(
                  child: Text('$day', style: TextStyle(fontWeight: FontWeight.bold, color: hasShift ? shiftColor : Colors.black87)),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}


// ==========================================
// 4. SHARED SCREENS (Chat & Profile)
// ==========================================

// GLOBAL CHAT FEED
class ChatFeedScreen extends StatefulWidget {
  final List<ChatMessage> messages;
  final String currentUser;
  final Color avatarColor;
  final Function(ChatMessage) onSendMessage;

  const ChatFeedScreen({super.key, required this.messages, required this.currentUser, required this.avatarColor, required this.onSendMessage});

  @override
  State<ChatFeedScreen> createState() => _ChatFeedScreenState();
}

class _ChatFeedScreenState extends State<ChatFeedScreen> {
  final _msgCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.centerLeft,
          child: const Text('Breakroom Feed', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.messages.length,
            itemBuilder: (context, index) {
              final msg = widget.messages[index];
              bool isMe = msg.senderName == widget.currentUser;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isMe) CircleAvatar(backgroundColor: msg.senderColor, radius: 16, child: Text(msg.senderName[0], style: const TextStyle(color: Colors.white, fontSize: 12))),
                    if (!isMe) const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF141927) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isMe ? null : Border.all(color: Colors.grey.shade300)
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe) Text(msg.senderName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: msg.senderColor)),
                            const SizedBox(height: 4),
                            Text(msg.message, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(child: TextField(controller: _msgCtrl, decoration: InputDecoration(hintText: 'Type a message...', filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)))),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFFC7A97A),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: () {
                    if (_msgCtrl.text.isNotEmpty) {
                      widget.onSendMessage(ChatMessage(senderName: widget.currentUser, senderColor: widget.avatarColor, message: _msgCtrl.text, time: 'Now'));
                      _msgCtrl.clear();
                    }
                  },
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}

// PROFILE & SETTINGS
class ProfileSettingsScreen extends StatefulWidget {
  final bool isEmployee;
  final String currentName;
  final String currentPassword;
  final Color currentAvatar;
  final Function(String) onUpdatePassword;
  final Function(Color) onUpdateAvatar;
  final VoidCallback onLogout;

  const ProfileSettingsScreen({super.key, required this.isEmployee, required this.currentName, required this.currentPassword, required this.currentAvatar, required this.onUpdatePassword, required this.onUpdateAvatar, required this.onLogout});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late TextEditingController _passCtrl;
  final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.pink, Colors.blueGrey, Colors.teal];

  @override
  void initState() {
    super.initState();
    _passCtrl = TextEditingController(text: widget.currentPassword);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Profile Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        Center(
          child: CircleAvatar(
            radius: 50,
            backgroundColor: widget.currentAvatar,
            child: Text(widget.currentName[0], style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 32),
        const Text('Select Profile Avatar Color', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12, runSpacing: 12,
          children: colors.map((c) => GestureDetector(
            onTap: () => widget.onUpdateAvatar(c),
            child: CircleAvatar(backgroundColor: c, radius: 24, child: widget.currentAvatar == c ? const Icon(Icons.check, color: Colors.white) : null),
          )).toList(),
        ),
        const SizedBox(height: 32),
        const Text('Security', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _passCtrl,
          decoration: const InputDecoration(labelText: 'Change Password', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            widget.onUpdatePassword(_passCtrl.text);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password Updated Successfully')));
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF141927), foregroundColor: Colors.white),
          child: const Text('Update Password'),
        ),
        const SizedBox(height: 48),
        OutlinedButton.icon(
          onPressed: widget.onLogout,
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56), side: const BorderSide(color: Colors.redAccent)),
        )
      ],
    );
  }
}