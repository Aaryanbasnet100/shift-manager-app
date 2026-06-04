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
          secondary: const Color(0xFFC7A97A), // Signature Gold
        ),
      ),
      home: const AuthGate(), // Starts at the login interceptor
    );
  }
}

// ==========================================
// 1. THE AUTHENTICATION GATE (LOGIN)
// ==========================================
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoggedIn = false;
  String _userRole = ''; // 'admin' or 'employee'

  void _login(String username, String password) {
    // Hardcoded logic for frontend testing
    if (username.toLowerCase() == 'admin' && password == 'admin123') {
      setState(() {
        _userRole = 'admin';
        _isLoggedIn = true;
      });
    } else if (username.toLowerCase() == 'crew' && password == 'crew123') {
      setState(() {
        _userRole = 'employee';
        _isLoggedIn = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid credentials. Try admin/admin123 or crew/crew123'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
      _userRole = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen(onLogin: _login);
    }

    // Route based on role
    if (_userRole == 'admin') {
      return AdminShell(onLogout: _logout);
    } else {
      return EmployeeShell(onLogout: _logout);
    }
  }
}

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
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFC7A97A).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.lock_person_rounded, color: Color(0xFFC7A97A), size: 40),
              ),
              const SizedBox(height: 24),
              const Text('System Access', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Enter operations credentials to continue.', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 48),
              TextField(
                controller: _userController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  hintText: 'Username (admin or crew)',
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
// 2. ADMIN ENVIRONMENT
// ==========================================
class AdminShell extends StatefulWidget {
  final VoidCallback onLogout;
  const AdminShell({super.key, required this.onLogout});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const AdminDashboard(),
      const AdminTeamManager(),
      Center(
        child: ElevatedButton(
          onPressed: widget.onLogout,
          child: const Text('Admin Logout'),
        ),
      ),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _currentIndex, children: screens)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF141927),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Command'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Crew Config'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Enterprise Command', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF141927), borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Labor Efficiency Target', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 12),
              const Text('18.4%', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Executing AI Schedule Optimization...')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC7A97A),
                  foregroundColor: const Color(0xFF141927),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome),
                    SizedBox(width: 8),
                    Text('Run AI Auto-Scheduler', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text('QUICK CREATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildAdminAction(Icons.person_add, 'New Crew\nAccount')),
            const SizedBox(width: 12),
            Expanded(child: _buildAdminAction(Icons.calendar_month, 'Publish\nShift')),
          ],
        )
      ],
    );
  }

  Widget _buildAdminAction(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF141927), size: 32),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class AdminTeamManager extends StatelessWidget {
  const AdminTeamManager({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Crew Accounts', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Manage active employee credentials and permissions.', style: TextStyle(color: Colors.blueGrey)),
          const SizedBox(height: 24),
          _buildCrewCard(context, 'James Chen', 'Cashier', 'Pass: crew123'),
          const SizedBox(height: 12),
          _buildCrewCard(context, 'Elena Valdes', 'Shift Lead', 'Pass: ev_lead99'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Open account creation modal
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const CreateAccountModal(),
          );
        },
        backgroundColor: const Color(0xFFC7A97A),
        icon: const Icon(Icons.add, color: Color(0xFF141927)),
        label: const Text('Create Account', style: TextStyle(color: Color(0xFF141927), fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCrewCard(BuildContext context, String name, String role, String password) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(role, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(password, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              )
            ],
          ),
          IconButton(icon: const Icon(Icons.edit), onPressed: () {})
        ],
      ),
    );
  }
}

class CreateAccountModal extends StatelessWidget {
  const CreateAccountModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Crew Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const TextField(decoration: InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          const TextField(decoration: InputDecoration(labelText: 'Role (e.g. Grill, Register)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          const TextField(decoration: InputDecoration(labelText: 'Temporary Password', border: OutlineInputBorder())),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: const Color(0xFF141927),
              foregroundColor: Colors.white,
            ),
            child: const Text('Generate Account'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ==========================================
// 3. EMPLOYEE ENVIRONMENT
// ==========================================
class EmployeeShell extends StatefulWidget {
  final VoidCallback onLogout;
  const EmployeeShell({super.key, required this.onLogout});

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const EmployeeDashboard(),
      Center(
        child: ElevatedButton(
          onPressed: widget.onLogout,
          child: const Text('Crew Logout'),
        ),
      ),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _currentIndex, children: screens)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF141927),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Terminal'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class EmployeeDashboard extends StatelessWidget {
  const EmployeeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Crew Terminal', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: [
              const Icon(Icons.fingerprint, size: 48, color: Color(0xFFC7A97A)),
              const SizedBox(height: 16),
              const Text('Ready to clock in for your shift?', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clocked into Front Counter.')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF141927),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Clock In - Front Counter', style: TextStyle(fontSize: 16)),
              )
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text('YOUR UPCOMING SCHEDULE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tomorrow', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Cashier • 14:00 - 22:00', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
              OutlinedButton(onPressed: () {}, child: const Text('Offer Swap'))
            ],
          ),
        )
      ],
    );
  }
}