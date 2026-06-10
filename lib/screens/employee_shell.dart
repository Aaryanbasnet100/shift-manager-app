import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../models/models.dart';
import '../services/austria_time.dart';
import '../services/availability.dart';
import '../services/password.dart';
import '../services/shift_conflict_engine.dart';
import '../services/shift_time.dart';
import '../theme/app_colors.dart';
import '../widgets/neon_calendar.dart';
import '../widgets/neon_stat_card.dart';
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
  // Feature 8: shift reminders posted at most once per shift per session.
  final Set<String> _remindersSent = {};

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

  // Feature 2: Real-Time Auto-Switching CET/CEST Clock (logic shared via services/austria_time.dart)
  void _updateTime() {
    final utcNow = DateTime.now().toUtc();
    bool isSummerTime = isCEST(utcNow);
    final austriaTime = utcNow.add(Duration(hours: isSummerTime ? 2 : 1));
    if (mounted) {
      setState(() {
        _currentTimeStr = "${austriaTime.hour.toString().padLeft(2, '0')}:${austriaTime.minute.toString().padLeft(2, '0')}:${austriaTime.second.toString().padLeft(2, '0')} ${isSummerTime ? 'CEST' : 'CET'}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [_buildDashboardView(), _buildGraphView(), _buildCalendarView(), _buildVacationView()];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        title: Text(widget.restaurantName.toUpperCase(), style: const TextStyle(color: AppColors.neonPurple, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        actions: [
          // Feature 12: profile & password change
          IconButton(icon: const Icon(Icons.person_outline, color: Colors.white54), onPressed: _openProfileSheet),
          // Feature 6 Trigger: Notification Bell.
          // Builder: Scaffold.of needs a context *below* this Scaffold.
          Builder(builder: (ctx) => IconButton(icon: const Badge(backgroundColor: AppColors.neonCyan, child: Icon(Icons.notifications_none, color: Colors.white54)), onPressed: () => Scaffold.of(ctx).openEndDrawer())),
          IconButton(icon: const Icon(Icons.power_settings_new, color: Colors.white54), onPressed: widget.onLogout)
        ]
      ),
      endDrawer: buildNotificationDrawer(context, widget.currentEmployee.restaurantId, employeeId: widget.currentEmployee.id),
      body: SafeArea(child: screens[_tabIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex, onTap: (i) => setState(() => _tabIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background, selectedItemColor: AppColors.neonCyan, unselectedItemColor: Colors.white38,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.space_dashboard), label: t('dashboard')),
          BottomNavigationBarItem(icon: const Icon(Icons.bar_chart), label: t('shift_graph')),
          BottomNavigationBarItem(icon: const Icon(Icons.calendar_month), label: t('calendar')),
          BottomNavigationBarItem(icon: const Icon(Icons.beach_access), label: t('vacation')),
        ],
      ),
    );
  }

  // Feature 12: profile sheet with password change.
  void _openProfileSheet() {
    final passCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('profile'), style: const TextStyle(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text(widget.currentEmployee.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          Text('${widget.currentEmployee.role} • @${widget.currentEmployee.username}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 24),
          buildNeonTextField(controller: passCtrl, hint: t('new_pass'), icon: Icons.lock_outline, isPassword: true),
          const SizedBox(height: 16),
          buildNeonButton(t('save'), () {
            if (passCtrl.text.isEmpty) return;
            FirebaseFirestore.instance.collection('restaurants').doc(widget.currentEmployee.restaurantId).collection('employees').doc(widget.currentEmployee.id).update({'password': encodePassword(passCtrl.text, '${widget.currentEmployee.restaurantId}:${widget.currentEmployee.username}')});
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.surface, content: Text(t('saved'), style: const TextStyle(color: Colors.white))));
          }),
          const SizedBox(height: 40),
        ],
      ),
    ));
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

  // Feature 1: Employee Dashboard — next-shift countdown, weekly hours,
  // pending request count. The 1s clock timer keeps the countdown live.
  Widget _buildDashboardView() {
    final now = austriaNow();
    final myShifts = widget.allShifts.where((s) => s.employeeId == widget.currentEmployee.id).toList();
    final next = _findNextShift(myShifts, now);
    final nextActive = next != null && isShiftActiveNow(next, now);
    _maybePostShiftReminder(next, now);

    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final weekDates = List.generate(7, (i) => monday.add(Duration(days: i)));
    final weekHours = myShifts.where((s) => weekDates.any((d) => occursOn(s, d))).fold<int>(0, (a, s) => a + s.durationHours);
    final pendingVacs = widget.vacations.where((v) => v.employeeName == widget.currentEmployee.name && v.status == 'Pending').length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildTopHeader(),
        // Feature 6: the open time entry stream drives the clock in/out button.
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('restaurants').doc(widget.currentEmployee.restaurantId).collection('timeEntries').where('employeeId', isEqualTo: widget.currentEmployee.id).where('clockOut', isNull: true).limit(1).snapshots(),
          builder: (context, teSnap) {
            final openEntry = (teSnap.hasData && teSnap.data!.docs.isNotEmpty) ? teSnap.data!.docs.first : null;
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: nextActive ? AppColors.neonCyan : AppColors.neonCyan.withValues(alpha: 0.3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t('next_shift'), style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      if (nextActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(gradient: AppColors.neonGradient, borderRadius: BorderRadius.circular(6)),
                          child: Text(t('on_shift_badge'), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (next == null)
                    Text(t('no_upcoming'), style: const TextStyle(color: Colors.white54))
                  else ...[
                    Text(next.timeWindow, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('${t('day')} ${next.dayOfMonth}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    if (!nextActive) ...[
                      const SizedBox(height: 12),
                      Builder(builder: (context) {
                        final startMin = effectiveStartMinutes(next);
                        final diff = DateTime(now.year, now.month, next.dayOfMonth, startMin ~/ 60, startMin % 60).difference(now);
                        final d = diff.inDays; final h = diff.inHours % 24; final m = diff.inMinutes % 60;
                        return Text('${t('starts_in')} $d${t('days_short')} $h${t('hours_short')} $m${t('min_short')}', style: const TextStyle(color: AppColors.neonCyan, fontSize: 20, fontWeight: FontWeight.w900));
                      }),
                    ],
                  ],
                  if (openEntry != null) ...[
                    const SizedBox(height: 16),
                    Builder(builder: (context) {
                      final ci = DateTime.tryParse((openEntry.data() as Map<String, dynamic>)['clockIn'] ?? '');
                      return Text(ci == null ? '' : '${t('clock_in')}: ${fmtMinutes(ci.hour * 60 + ci.minute)}', style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold));
                    }),
                    const SizedBox(height: 8),
                    buildNeonButton(t('clock_out'), () => openEntry.reference.update({'clockOut': austriaNow().toIso8601String()})),
                  ] else if (next != null && nextActive) ...[
                    const SizedBox(height: 16),
                    buildNeonButton(t('clock_in'), () => _clockIn(next)),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
          children: [
            NeonStatCard(icon: Icons.timelapse, value: weekHours, label: t('hours_this_week'), onTap: () => setState(() => _tabIndex = 1)),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('restaurants').doc(widget.currentEmployee.restaurantId).collection('swapRequests').where('requesterId', isEqualTo: widget.currentEmployee.id).where('status', isEqualTo: 'pending').snapshots(),
              builder: (context, snap) {
                final pendingSwaps = snap.hasData ? snap.data!.docs.length : 0;
                return NeonStatCard(icon: Icons.pending_actions, value: pendingSwaps + pendingVacs, label: t('my_pending'), alert: true, onTap: () => setState(() => _tabIndex = 3));
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Feature 5: open-shift marketplace — volunteer for unassigned shifts.
        Text(t('open_shifts'), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Builder(builder: (context) {
          final openShifts = widget.allShifts.where((s) =>
            s.isOpenShift &&
            s.dayOfMonth >= now.day &&
            (s.month == null || s.month == now.month) &&
            (s.year == null || s.year == now.year)).toList()
            ..sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
          if (openShifts.isEmpty) return Text(t('no_open_shifts'), style: const TextStyle(color: Colors.white54));
          return Column(
            children: openShifts.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.4))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${t('day')} ${s.dayOfMonth}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(s.timeWindow, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  TextButton(onPressed: () => _volunteerForShift(s, now), child: Text(t('volunteer'), style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w900, letterSpacing: 1))),
                ],
              ),
            )).toList(),
          );
        }),
      ],
    );
  }

  // Feature 8: in-app reminder when the next shift starts within 2 hours.
  // Deterministic doc id keeps it to one reminder per shift even across
  // sessions; the local set avoids rewriting it every clock tick.
  void _maybePostShiftReminder(ShiftData? next, DateTime now) {
    if (next == null) return;
    final key = 'rem_${next.id}_${widget.currentEmployee.id}';
    if (_remindersSent.contains(key)) return;
    final startMin = effectiveStartMinutes(next);
    final start = DateTime(now.year, now.month, next.dayOfMonth, startMin ~/ 60, startMin % 60);
    final diff = start.difference(now);
    if (diff.isNegative || diff.inMinutes > 120) return;
    _remindersSent.add(key);
    FirebaseFirestore.instance.collection('restaurants').doc(widget.currentEmployee.restaurantId).collection('notifications').doc(key).set({
      'msg': '${t('shift_reminder')}${fmtMinutes(startMin)}', 'read': false, 'time': DateTime.now().toIso8601String(), 'targetEmployeeId': widget.currentEmployee.id,
    });
  }

  // Feature 6: time clock — snapshot the scheduled window so the attendance
  // log can flag late starts and early leaves even if the shift changes later.
  void _clockIn(ShiftData s) {
    final now = austriaNow();
    FirebaseFirestore.instance.collection('restaurants').doc(widget.currentEmployee.restaurantId).collection('timeEntries').add({
      'employeeId': widget.currentEmployee.id, 'employeeName': widget.currentEmployee.name, 'shiftId': s.id,
      'clockIn': now.toIso8601String(), 'clockOut': null,
      'dayOfMonth': now.day, 'month': now.month, 'year': now.year,
      'scheduledStartMinutes': effectiveStartMinutes(s), 'scheduledEndMinutes': effectiveEndMinutes(s),
    });
  }

  Future<void> _volunteerForShift(ShiftData s, DateTime now) async {
    final date = DateTime(s.year ?? now.year, s.month ?? now.month, s.dayOfMonth);
    if (!await checkShiftConflict(context, widget.allShifts, widget.currentEmployee.id, date)) return;
    final ws = FirebaseFirestore.instance.collection('restaurants').doc(widget.currentEmployee.restaurantId);
    WriteBatch batch = FirebaseFirestore.instance.batch();
    batch.set(ws.collection('swapRequests').doc(), {'type': 'claim', 'requesterId': widget.currentEmployee.id, 'requesterName': widget.currentEmployee.name, 'targetId': '', 'targetName': '', 'shiftId': s.id, 'status': 'pending'});
    batch.set(ws.collection('notifications').doc(), {'msg': '${t('noti_claim')}${widget.currentEmployee.name}', 'read': false, 'time': DateTime.now().toIso8601String()});
    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.surface, content: Text(t('pending'), style: const TextStyle(color: Colors.white))));
    }
  }

  // Earliest shift (this month) that hasn't ended yet, by day + start time.
  ShiftData? _findNextShift(List<ShiftData> shifts, DateTime now) {
    ShiftData? best;
    DateTime? bestStart;
    for (final s in shifts) {
      if (s.dayOfMonth < now.day) continue;
      if (s.month != null && s.month != now.month) continue;
      if (s.year != null && s.year != now.year) continue;
      final startMin = effectiveStartMinutes(s);
      var endMin = effectiveEndMinutes(s);
      if (endMin <= startMin) endMin = 1440; // overnight: treat as ending at midnight
      final end = DateTime(now.year, now.month, s.dayOfMonth, endMin ~/ 60, endMin % 60);
      if (end.isBefore(now)) continue;
      final start = DateTime(now.year, now.month, s.dayOfMonth, startMin ~/ 60, startMin % 60);
      if (bestStart == null || start.isBefore(bestStart)) { best = s; bestStart = start; }
    }
    return best;
  }

  Widget _buildGraphView() {
    // Monthly view: dated shifts from the current month plus legacy
    // (undated) shifts, so the hours tracker stays accurate.
    final now = austriaNow();
    final myShifts = widget.allShifts.where((s) => s.employeeId == widget.currentEmployee.id && (s.month == null || s.month == now.month) && (s.year == null || s.year == now.year)).toList();

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
          onTap: () => _openShiftActions(shift),
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

  // Feature 5: swap with a colleague or offer the shift for drop —
  // both go through the manager's approval queue.
  void _openShiftActions(ShiftData shift) {
    final ws = FirebaseFirestore.instance.collection('restaurants').doc(widget.currentEmployee.restaurantId);
    String targetEmpId = widget.allEmployees.firstWhere((e) => e.id != widget.currentEmployee.id, orElse: () => widget.currentEmployee).id;
    showModalBottomSheet(context: context, backgroundColor: AppColors.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t('request_swap'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(value: targetEmpId, dropdownColor: AppColors.surface, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: widget.allEmployees.where((e) => e.id != widget.currentEmployee.id).map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(), onChanged: (val) { if(val != null) setModalState(() => targetEmpId = val); }),
          const SizedBox(height: 24),
          buildNeonButton(t('request_swap'), () {
            final tEmp = widget.allEmployees.firstWhere((e) => e.id == targetEmpId);
            WriteBatch batch = FirebaseFirestore.instance.batch();
            batch.set(ws.collection('swapRequests').doc(), {'type': 'swap', 'requesterId': widget.currentEmployee.id, 'requesterName': widget.currentEmployee.name, 'targetId': tEmp.id, 'targetName': tEmp.name, 'shiftId': shift.id, 'status': 'pending'});
            batch.set(ws.collection('notifications').doc(), {'msg': '${t('noti_swap_offered')}${widget.currentEmployee.name}', 'read': false, 'time': DateTime.now().toIso8601String()});
            batch.commit();
            Navigator.pop(ctx);
          }),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              WriteBatch batch = FirebaseFirestore.instance.batch();
              batch.set(ws.collection('swapRequests').doc(), {'type': 'drop', 'requesterId': widget.currentEmployee.id, 'requesterName': widget.currentEmployee.name, 'targetId': '', 'targetName': '', 'shiftId': shift.id, 'status': 'pending'});
              batch.set(ws.collection('notifications').doc(), {'msg': '${t('noti_drop_offered')}${widget.currentEmployee.name}', 'read': false, 'time': DateTime.now().toIso8601String()});
              batch.commit();
              Navigator.pop(ctx);
            },
            child: Text(t('offer_drop'), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    )));
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
          onDayTap: !widget.currentEmployee.canManageShifts ? null : (date) => _openSelfScheduleSheet(date),
        ),
      ],
    );
  }

  void _openSelfScheduleSheet(DateTime date) {
    String selectedSlot = t('morning');
    showModalBottomSheet(
      context: context, backgroundColor: AppColors.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${t('schedule_for')}${date.day} ${t('month_${date.month}')}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
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
                if (await checkShiftConflict(context, widget.allShifts, widget.currentEmployee.id, date)) {
                  final w = parseWindow(selectedSlot);
                  FirebaseFirestore.instance.collection('restaurants').doc(widget.currentEmployee.restaurantId).collection('shifts').add({
                    'restaurantId': widget.currentEmployee.restaurantId, 'employeeId': widget.currentEmployee.id, 'employeeName': widget.currentEmployee.name, 'timeWindow': selectedSlot,
                    'dayOfMonth': date.day, 'month': date.month, 'year': date.year,
                    if (w != null) 'startMinutes': w.start * 60, if (w != null) 'endMinutes': w.end * 60,
                    'durationHours': 8
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
              'restaurantId': widget.currentEmployee.restaurantId, 'employeeName': widget.currentEmployee.name, 'dates': dates, 'status': 'Pending',
              // Feature 4: ISO dates + id so the scheduler can detect leave overlap.
              'employeeId': widget.currentEmployee.id,
              'startDate': picked.start.toIso8601String(), 'endDate': picked.end.toIso8601String(),
            });
          }
        }),
        const SizedBox(height: 24),
        ...myVacations.map((vac) => Container(
          margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: ListTile(title: Text(vac.dates, style: const TextStyle(color: Colors.white)), trailing: Text(t(vac.status.toLowerCase()), style: TextStyle(color: vac.status == 'Pending' ? Colors.orange : (vac.status == 'Denied' ? Colors.redAccent : Colors.green), fontWeight: FontWeight.bold))),
        )),
        const SizedBox(height: 32),
        // Feature 4: recurring weekly availability editor.
        Text(t('availability'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white54)),
        const SizedBox(height: 16),
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('restaurants').doc(widget.currentEmployee.restaurantId).collection('availability').doc(widget.currentEmployee.id).snapshots(),
          builder: (context, snap) {
            final data = snap.hasData && snap.data!.exists ? snap.data!.data() as Map<String, dynamic> : null;
            return Column(
              children: List.generate(7, (i) {
                final wd = i + 1;
                final status = availabilityStatus(data, wd);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                  child: Row(
                    children: [
                      SizedBox(width: 40, child: Text(t('wd_$wd'), style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900))),
                      Expanded(
                        child: Wrap(
                          spacing: 6, alignment: WrapAlignment.end,
                          children: [
                            _availChip(t('available'), status == 'available', AppColors.neonCyan, () => _setAvailability(wd, 'available')),
                            _availChip(t('preferred'), status == 'preferred', AppColors.neonPurple, () => _setAvailability(wd, 'preferred')),
                            _availChip(t('unavailable'), status == 'unavailable', Colors.redAccent, () => _setAvailability(wd, 'unavailable')),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  void _setAvailability(int weekday, String status) {
    FirebaseFirestore.instance.collection('restaurants').doc(widget.currentEmployee.restaurantId).collection('availability').doc(widget.currentEmployee.id).set({'wd$weekday': status}, SetOptions(merge: true));
  }

  Widget _availChip(String label, bool selected, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : Colors.white12),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
