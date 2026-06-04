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
      title: 'Shift Manager',
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
      home: const MainAppShell(),
    );
  }
}

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ScheduleScreen(),
    const DirectoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF141927),
            unselectedItemColor: Colors.grey[500],
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Schedule'),
              BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded), label: 'Directory'),
              BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 1. DASHBOARD SCREEN
// ==========================================
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tuesday, June 2',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Welcome back,\nBasnet',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.1, color: Color(0xFF141927)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
              child: const Stack(
                children: [
                  Icon(Icons.notifications_none_rounded, size: 28),
                  Positioned(right: 2, top: 2, child: CircleAvatar(radius: 4, backgroundColor: Colors.redAccent))
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF141927),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF141927).withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 6))]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('On Shift Now', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text('5', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                        Text(' /7', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 18, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))]
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pending\nApprovals', style: TextStyle(color: Colors.blueGrey, fontSize: 15, fontWeight: FontWeight.w500, height: 1.2)),
                    SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('3', style: TextStyle(color: Color(0xFF141927), fontSize: 40, fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Text('requests', style: TextStyle(color: Colors.blueGrey, fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text('QUICK ACTIONS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFF141927))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionIcon(Icons.add, 'Create\nShift'),
              _buildActionIcon(Icons.sync_rounded, 'Find\nCover'),
              _buildActionIcon(Icons.chat_bubble_outline_rounded, 'Message\nTeam'),
              _buildActionIcon(Icons.description_outlined, 'Daily\nReport'),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('LIVE ROSTER', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFF141927))),
            Text('View All', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: [
              _buildRosterRow('Elena Valdes', 'Front Register', '14:00 - 22:00', true, "EV", Colors.blue.shade100),
              Divider(height: 1, color: Colors.grey.shade100, indent: 80),
              _buildRosterRow('Marcus Thorne', 'Drive-Thru', '15:00 - 23:00', true, "MT", Colors.orange.shade100),
              Divider(height: 1, color: Colors.grey.shade100, indent: 80),
              _buildRosterRow('Sarah Jenkins', 'Assembly Line', '16:00 - 00:00', false, "SJ", Colors.purple.shade100),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
          child: Icon(icon, color: const Color(0xFF141927), size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
      ],
    );
  }

  Widget _buildRosterRow(String name, String role, String time, bool isClockedIn, String initials, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(radius: 24, backgroundColor: color, child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              if (isClockedIn)
                Positioned(bottom: 0, right: 0, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF141927))),
                Text(role, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF141927))),
              Text(isClockedIn ? 'Clocked in' : 'Scheduled', style: TextStyle(color: isClockedIn ? Colors.blueGrey : Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}

// ==========================================
// 2. SCHEDULE SCREEN
// ==========================================
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedDateIndex = 2; 

  final List<Map<String, String>> _dates = [
    {'day': 'Sun', 'date': '31'}, {'day': 'Mon', 'date': '1'}, {'day': 'Tue', 'date': '2'},
    {'day': 'Wed', 'date': '3'}, {'day': 'Thu', 'date': '4'}, {'day': 'Fri', 'date': '5'}, {'day': 'Sat', 'date': '6'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        const Text('Master Schedule', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF141927))),
        const SizedBox(height: 24),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _dates.length,
            itemBuilder: (context, index) {
              final isSelected = index == _selectedDateIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedDateIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF141927) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? const Color(0xFF141927) : Colors.grey.shade200),
                    boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF141927).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_dates[index]['day']!, style: TextStyle(color: isSelected ? Colors.white70 : Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(_dates[index]['date']!, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF141927), fontSize: 20, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add, size: 20), SizedBox(width: 8), Text('Create New Shift', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
        ),
        const SizedBox(height: 32),
        const Text('FRONT COUNTER', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFF141927))),
        const SizedBox(height: 16),
        _buildShiftCard('Elena Valdes', '14:00 - 22:00', "EV", Colors.blue.shade100),
        const SizedBox(height: 12),
        _buildShiftCard('James Chen', '18:00 - 02:00', "JC", Colors.green.shade100),
        const SizedBox(height: 12),
        _buildShiftCard('Maria Santos', '20:00 - 04:00', "MS", Colors.pink.shade100),
        const SizedBox(height: 32),
        const Text('KITCHEN CREW', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFF141927))),
        const SizedBox(height: 16),
        _buildShiftCard('Marcus Thorne', '15:00 - 23:00', "MT", Colors.orange.shade100),
        const SizedBox(height: 12),
        _buildShiftCard('Sarah Jenkins', '06:00 - 14:00', "SJ", Colors.purple.shade100),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildShiftCard(String name, String time, String initials, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          CircleAvatar(radius: 26, backgroundColor: color, child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF141927))),
                const SizedBox(height: 4),
                Row(children: [const Icon(Icons.access_time_rounded, size: 14, color: Colors.blueGrey), const SizedBox(width: 4), Text(time, style: const TextStyle(color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.w500))]),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
            child: IconButton(icon: const Icon(Icons.edit_outlined, size: 20), color: const Color(0xFF141927), onPressed: () {}),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 3. DIRECTORY SCREEN
// ==========================================
class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        const Text('Team Directory', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF141927))),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey.shade400),
                    hintText: 'Search staff...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Icon(Icons.filter_list_rounded, color: Colors.grey.shade600),
            )
          ],
        ),
        const SizedBox(height: 32),
        const Text('MANAGEMENT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFF141927))),
        const SizedBox(height: 16),
        _buildDirectoryCard('Basnet', 'Shift Supervisor', '+1 555-0100', "B", Colors.teal.shade100, isManager: true),
        const SizedBox(height: 32),
        const Text('FRONT COUNTER', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFF141927))),
        const SizedBox(height: 16),
        _buildDirectoryCard('James Chen', 'Cashier', '+1 555-0104', "JC", Colors.green.shade100),
        const SizedBox(height: 12),
        _buildDirectoryCard('Elena Valdes', 'Shift Lead', '+1 555-0101', "EV", Colors.blue.shade100),
        const SizedBox(height: 12),
        _buildDirectoryCard('Maria Santos', 'Drive-Thru', '+1 555-0106', "MS", Colors.pink.shade100),
        const SizedBox(height: 32),
        const Text('KITCHEN CREW', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFF141927))),
        const SizedBox(height: 16),
        _buildDirectoryCard('Marcus Thorne', 'Grill Cook', '+1 555-0108', "MT", Colors.orange.shade100),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDirectoryCard(String name, String role, String phone, String initials, Color color, {bool isManager = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          CircleAvatar(radius: 26, backgroundColor: color, child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF141927))),
                Text(role, style: TextStyle(color: isManager ? const Color(0xFFC7A97A) : Colors.blueGrey, fontSize: 13, fontWeight: isManager ? FontWeight.bold : FontWeight.normal)),
                const SizedBox(height: 2),
                Text(phone, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.phone_outlined, size: 18, color: Colors.green),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF141927)),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// ==========================================
// 4. SETTINGS SCREEN
// ==========================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.teal.shade100,
                child: const Text("B", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
                  child: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF141927)),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Center(child: Text('Supervisor Basnet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF141927)))),
        const SizedBox(height: 4),
        const Center(child: Text('Shift Supervisor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFC7A97A)))),
        const SizedBox(height: 40),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: [
              _buildSettingsRow(Icons.person_outline_rounded, 'Account Settings'),
              Divider(height: 1, color: Colors.grey.shade100, indent: 60),
              _buildSettingsRow(Icons.store_outlined, 'App Preferences'),
              Divider(height: 1, color: Colors.grey.shade100, indent: 60),
              _buildSettingsRow(Icons.notifications_none_rounded, 'Notification Rules'),
              Divider(height: 1, color: Colors.grey.shade100, indent: 60),
              _buildSettingsRow(Icons.link_rounded, 'Staff Invite Links'),
              Divider(height: 1, color: Colors.grey.shade100, indent: 60),
              _buildSettingsRow(Icons.download_rounded, 'Export Payroll Data'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            side: const BorderSide(color: Colors.redAccent),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Log Out', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSettingsRow(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
            child: Icon(icon, color: const Color(0xFF141927), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF141927)))),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}