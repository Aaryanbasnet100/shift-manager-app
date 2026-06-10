import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../models/models.dart';
import '../services/shift_conflict_engine.dart';
import '../theme/app_colors.dart';
import '../widgets/neon_calendar.dart';
import '../widgets/neon_widgets.dart';
import '../widgets/notification_drawer.dart';

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
        backgroundColor: AppColors.background, elevation: 0,
        title: Text(widget.restaurantName.toUpperCase(), style: const TextStyle(color: AppColors.neonPurple, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        actions: [
          // Feature 6 Trigger: Notification Bell
          IconButton(icon: const Badge(backgroundColor: AppColors.neonCyan, child: Icon(Icons.notifications_none, color: Colors.white54)), onPressed: () => Scaffold.of(context).openEndDrawer()),
          IconButton(icon: const Icon(Icons.power_settings_new, color: Colors.white54), onPressed: widget.onLogout)
        ]
      ),
      endDrawer: buildNotificationDrawer(context, widget.currentEmployee.restaurantId),
      body: SafeArea(child: screens[_tabIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex, onTap: (i) => setState(() => _tabIndex = i),
        backgroundColor: AppColors.background, selectedItemColor: AppColors.neonCyan, unselectedItemColor: Colors.white38,
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
          decoration: BoxDecoration(color: AppColors.neonPurple.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.neonPurple)),
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
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: isOvertime ? Colors.redAccent : Colors.white.withValues(alpha: 0.05))),
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
                LinearProgressIndicator(value: progress, backgroundColor: Colors.white.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation<Color>(isOvertime ? Colors.purpleAccent : AppColors.neonCyan), minHeight: 8, borderRadius: BorderRadius.circular(4)),
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
            showModalBottomSheet(context: context, backgroundColor: AppColors.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(t('request_swap'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 24), DropdownButtonFormField<String>(value: targetEmpId, dropdownColor: AppColors.surface, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: widget.allEmployees.where((e) => e.id != widget.currentEmployee.id).map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(), onChanged: (val) { if(val != null) setModalState(() => targetEmpId = val); }), const SizedBox(height: 24), buildNeonButton(t('request_swap'), () { final tEmp = widget.allEmployees.firstWhere((e) => e.id == targetEmpId); FirebaseFirestore.instance.collection('restaurants').doc(widget.currentEmployee.restaurantId).collection('swapRequests').add({'requesterId': widget.currentEmployee.id, 'requesterName': widget.currentEmployee.name, 'targetId': tEmp.id, 'targetName': tEmp.name, 'shiftId': shift.id, 'status': 'pending'}); Navigator.pop(ctx); })]))));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
            child: ListTile(
              leading: const Icon(Icons.swap_calls, color: AppColors.neonCyan),
              title: Text('${shift.timeWindow} (${t('day')} ${shift.dayOfMonth})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(t('tap_swap'), style: const TextStyle(color: Colors.white54)),
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
        // Feature 9: Self-Schedule Calendar (Issue 3 redesign).
        // Issue 2: self-scheduling is a privileged action — plain employees
        // get a read-only calendar (onDayTap disabled).
        NeonCalendar(
          shifts: myShifts,
          onDayTap: !widget.currentEmployee.canManageShifts ? null : (day) => _openSelfScheduleSheet(day),
        ),
      ],
    );
  }

  void _openSelfScheduleSheet(int day) {
    String selectedSlot = t('morning');
    showModalBottomSheet(
      context: context, backgroundColor: AppColors.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${t('schedule_for')}$day', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: selectedSlot, dropdownColor: AppColors.surface, style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                items: [t('morning'), t('afternoon'), t('night')].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) { if(val != null) setModalState(() => selectedSlot = val); },
              ),
              const SizedBox(height: 24),
              buildNeonButton(t('deploy_shift'), () async {
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
        buildNeonButton(t('req_vacation'), () async {
          final DateTimeRange? picked = await showDateRangePicker(
            context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
            builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.neonCyan, surface: AppColors.surface, onSurface: Colors.white)), child: child!),
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
          margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: ListTile(title: Text(vac.dates, style: const TextStyle(color: Colors.white)), trailing: Text(t(vac.status.toLowerCase()), style: TextStyle(color: vac.status == 'Pending' ? Colors.orange : Colors.green, fontWeight: FontWeight.bold))),
        )),
      ],
    );
  }
}
