import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../models/models.dart';
import '../services/austria_time.dart';
import '../services/availability.dart';
import '../services/shift_conflict_engine.dart';
import '../services/shift_time.dart';
import '../theme/app_colors.dart';
import '../widgets/neon_stat_card.dart';
import '../widgets/neon_widgets.dart';
import '../widgets/notification_drawer.dart';

// ==========================================
// MANAGER SHELL (Issue 4)
// Team overview, week schedule with shift CRUD, request approvals,
// and team announcements. Scoped to the whole workspace for now —
// location filtering slots in here once multi-location lands.
// ==========================================
class ManagerShell extends StatefulWidget {
  final String restaurantName; final String workspaceId; final VoidCallback onLogout;
  final EmployeeData currentManager;
  final List<EmployeeData> employees; final List<ShiftData> shifts; final List<VacationData> vacations;
  const ManagerShell({super.key, required this.restaurantName, required this.workspaceId, required this.onLogout, required this.currentManager, required this.employees, required this.shifts, required this.vacations});
  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _tabIndex = 0;
  int _weekOffset = 0;
  final _announceCtrl = TextEditingController();

  DocumentReference get _wsDoc => FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId);

  @override
  void dispose() {
    _announceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [_buildDashboardTab(), _buildTeamTab(), _buildScheduleTab(), _buildRequestsTab(), _buildAnnounceTab()];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        title: Text('${t('manager_prefix')}: ${widget.restaurantName}', style: const TextStyle(color: AppColors.neonCyan, fontSize: 14, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(icon: const Badge(backgroundColor: AppColors.neonCyan, child: Icon(Icons.notifications_none, color: Colors.white54)), onPressed: () => Scaffold.of(context).openEndDrawer()),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white54), onPressed: widget.onLogout)
        ]
      ),
      endDrawer: buildNotificationDrawer(context, widget.workspaceId, employeeId: widget.currentManager.id),
      body: screens[_tabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex, onTap: (i) => setState(() => _tabIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background, selectedItemColor: AppColors.neonCyan, unselectedItemColor: Colors.white38,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.space_dashboard), label: t('dashboard')),
          BottomNavigationBarItem(icon: const Icon(Icons.groups_2), label: t('my_team')),
          BottomNavigationBarItem(icon: const Icon(Icons.calendar_view_week), label: t('schedule')),
          BottomNavigationBarItem(icon: const Icon(Icons.how_to_reg), label: t('requests')),
          BottomNavigationBarItem(icon: const Icon(Icons.campaign), label: t('announce')),
        ],
      ),
    );
  }

  // --- Tab 0: Dashboard (Feature 1) -------------------------------------
  Widget _buildDashboardTab() {
    final now = austriaNow();
    final todayShifts = widget.shifts.where((s) => occursOn(s, now)).toList();
    final onShiftNow = todayShifts.where((s) => !s.isOpenShift && isShiftActiveNow(s, now)).length;
    final pendingVacs = widget.vacations.where((v) => v.status == 'Pending').length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(t('dashboard'), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
          children: [
            NeonStatCard(icon: Icons.people_alt, value: onShiftNow, label: t('on_shift_now')),
            NeonStatCard(icon: Icons.event_available, value: todayShifts.length, label: t('shifts_today')),
            StreamBuilder<QuerySnapshot>(
              stream: _wsDoc.collection('swapRequests').where('status', isEqualTo: 'pending').snapshots(),
              builder: (context, snap) {
                final pendingSwaps = snap.hasData ? snap.data!.docs.length : 0;
                return NeonStatCard(icon: Icons.how_to_reg, value: pendingSwaps + pendingVacs, label: t('pending_requests'), alert: true, onTap: () => setState(() => _tabIndex = 3));
              },
            ),
            NeonStatCard(icon: Icons.groups_2, value: widget.employees.length, label: t('team_size'), onTap: () => setState(() => _tabIndex = 1)),
          ],
        ),
        const SizedBox(height: 32),
        Text(t('todays_coverage'), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        if (todayShifts.isEmpty) Text(t('no_shifts_today'), style: const TextStyle(color: Colors.white54)),
        ...todayShifts.map((s) {
          final active = isShiftActiveNow(s, now);
          return InkWell(
            onTap: () => _openEditShiftSheet(s),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? AppColors.neonCyan : Colors.white.withValues(alpha: 0.05))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.isOpenShift ? t('open_shift') : s.employeeName, style: TextStyle(color: s.isOpenShift ? AppColors.neonCyan : Colors.white, fontWeight: FontWeight.bold)),
                        Text(s.timeWindow, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (active)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(gradient: AppColors.neonGradient, borderRadius: BorderRadius.circular(6)),
                      child: Text(t('on_shift_badge'), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- Tab 1: My Team -------------------------------------------------
  Widget _buildTeamTab() {
    final now = austriaNow();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final weekDates = List.generate(7, (i) => monday.add(Duration(days: i)));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(t('my_team'), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 24),
        ...widget.employees.map((emp) {
          final hours = widget.shifts.where((s) => s.employeeId == emp.id && weekDates.any((d) => occursOn(s, d))).fold<int>(0, (a, s) => a + s.durationHours);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              // Feature 6: tap for the attendance log.
              onTap: () => _openAttendanceSheet(emp),
              leading: CircleAvatar(backgroundColor: AppColors.neonPurple.withValues(alpha: 0.3), child: Text(emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              title: Text(emp.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(emp.role, style: const TextStyle(color: Colors.white54)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${hours}h', style: const TextStyle(color: AppColors.neonCyan, fontSize: 16, fontWeight: FontWeight.w900)),
                  Text(t('this_week'), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- Feature 6: Attendance log ----------------------------------------
  void _openAttendanceSheet(EmployeeData emp) {
    final now = austriaNow();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${t('attendance')}: ${emp.name}', style: const TextStyle(color: AppColors.neonCyan, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: StreamBuilder<QuerySnapshot>(
              stream: _wsDoc.collection('timeEntries').where('employeeId', isEqualTo: emp.id).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
                final entries = snap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList()
                  ..sort((a, b) => (b['clockIn'] ?? '').toString().compareTo((a['clockIn'] ?? '').toString()));
                if (entries.isEmpty) return Padding(padding: const EdgeInsets.only(bottom: 24), child: Text(t('no_entries'), style: const TextStyle(color: Colors.white54)));

                // Month summary: actual (closed entries) vs scheduled minutes.
                int actualMin = 0, schedMin = 0;
                for (final e in entries) {
                  if (e['month'] != now.month || e['year'] != now.year) continue;
                  final ci = DateTime.tryParse(e['clockIn'] ?? ''); final co = DateTime.tryParse(e['clockOut'] ?? '');
                  if (ci != null && co != null) actualMin += co.difference(ci).inMinutes;
                  final ss = e['scheduledStartMinutes'] as int?; final se = e['scheduledEndMinutes'] as int?;
                  if (ss != null && se != null) schedMin += (se - ss + 1440) % 1440;
                }
                String hm(int m) => '${m ~/ 60}${t('hours_short')} ${m % 60}${t('min_short')}';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${t('actual')}: ${hm(actualMin)}  •  ${t('scheduled_lbl')}: ${hm(schedMin)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: entries.map((e) {
                          final ci = DateTime.tryParse(e['clockIn'] ?? '');
                          final co = DateTime.tryParse(e['clockOut'] ?? '');
                          if (ci == null) return const SizedBox.shrink();
                          final ciMin = ci.hour * 60 + ci.minute;
                          final coMin = co != null ? co.hour * 60 + co.minute : null;
                          final ss = e['scheduledStartMinutes'] as int?;
                          final se = e['scheduledEndMinutes'] as int?;
                          final isLate = ss != null && ciMin > ss + 5;
                          final leftEarly = co != null && se != null && se > (ss ?? 0) && coMin! < se - 5;
                          final actual = co?.difference(ci).inMinutes;

                          Widget badge(String label, Color color) => Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: color)),
                            child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900)),
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: co == null ? AppColors.neonCyan : Colors.white.withValues(alpha: 0.05))),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Text('${ci.day}.${ci.month}.', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                        if (co == null) badge(t('active_now'), AppColors.neonCyan),
                                        if (isLate) badge(t('late'), Colors.orange),
                                        if (leftEarly) badge(t('early_leave'), Colors.redAccent),
                                      ]),
                                      Text('${fmtMinutes(ciMin)} - ${coMin != null ? fmtMinutes(coMin) : '…'}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                if (actual != null) Text(hm(actual), style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w900, fontSize: 12)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ));
  }

  // --- Tab 2: Schedule (week view + shift CRUD) ------------------------
  List<DateTime> get _visibleWeek {
    final now = austriaNow();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1)).add(Duration(days: _weekOffset * 7));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  Widget _buildScheduleTab() {
    final days = _visibleWeek;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t('schedule'), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            // Feature 3: shift templates
            IconButton(icon: const Icon(Icons.layers_outlined, color: AppColors.neonCyan), onPressed: _openTemplatesSheet),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left_rounded, color: AppColors.neonCyan, size: 28), onPressed: () => setState(() => _weekOffset--)),
            Text('${days.first.day} – ${days.last.day} ${t('month_${days.last.month}')}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
            IconButton(icon: const Icon(Icons.chevron_right_rounded, color: AppColors.neonCyan, size: 28), onPressed: () => setState(() => _weekOffset++)),
          ],
        ),
        const SizedBox(height: 8),
        ...days.map((d) {
          final dayShifts = widget.shifts.where((s) => occursOn(s, d)).toList();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${t('wd_${d.weekday}')} ${d.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.neonCyan, size: 20), onPressed: () => _openCreateShiftSheet(d)),
                  ],
                ),
                if (dayShifts.isEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t('no_shifts'), style: const TextStyle(color: Colors.white38, fontSize: 12))),
                ...dayShifts.map((s) => InkWell(
                  onTap: () => _openEditShiftSheet(s),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3))),
                    child: Row(
                      children: [
                        Expanded(child: Text('${s.isOpenShift ? t('open_shift') : s.employeeName} • ${s.timeWindow}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: s.isOpenShift ? AppColors.neonCyan : Colors.white, fontSize: 12))),
                        Text('${s.durationHours}h', style: const TextStyle(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Schedule v2: tappable time field driving showTimePicker, themed dark.
  Widget _timePickerField(BuildContext ctx, String label, int minutes, ValueChanged<int> onPicked) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: ctx, initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
          builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.neonCyan, surface: AppColors.surface, onSurface: Colors.white)), child: child!),
        );
        if (picked != null) onPicked(picked.hour * 60 + picked.minute);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(fmtMinutes(minutes), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  void _openCreateShiftSheet(DateTime date) {
    if (widget.employees.isEmpty) return;
    String empId = widget.employees.first.id;
    int startMin = 9 * 60; int endMin = 17 * 60;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${t('schedule_for')}${date.day} ${t('month_${date.month}')}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(value: empId, dropdownColor: AppColors.surface, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: [
          // Feature 5: post the shift unassigned to the open-shift board.
          DropdownMenuItem(value: '', child: Text(t('open_shift'), style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w900))),
          ...widget.employees.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))),
        ], onChanged: (val) { if (val != null) setModalState(() => empId = val); }),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _timePickerField(ctx, t('start_time'), startMin, (v) => setModalState(() => startMin = v))),
          const SizedBox(width: 12),
          Expanded(child: _timePickerField(ctx, t('end_time'), endMin, (v) => setModalState(() => endMin = v))),
        ]),
        const SizedBox(height: 24),
        buildNeonButton(t('deploy_shift'), () async {
          final isOpen = empId.isEmpty;
          if (!isOpen) {
            final emp = widget.employees.firstWhere((e) => e.id == empId);
            if (!await _availabilityOk(ctx, emp, date)) return;
            if (!ctx.mounted) return;
            if (!await checkShiftConflict(ctx, widget.shifts, empId, date)) return;
          }
          final emp = isOpen ? null : widget.employees.firstWhere((e) => e.id == empId);
          final durMin = (endMin - startMin + 1440) % 1440;
          _wsDoc.collection('shifts').add({
            'restaurantId': widget.workspaceId, 'employeeId': emp?.id ?? '', 'employeeName': emp?.name ?? '',
            'timeWindow': '${fmtMinutes(startMin)} - ${fmtMinutes(endMin)}',
            'dayOfMonth': date.day, 'month': date.month, 'year': date.year,
            'startMinutes': startMin, 'endMinutes': endMin,
            'durationHours': (durMin / 60).round(),
            'isOpenShift': isOpen,
          });
          if (ctx.mounted) Navigator.pop(ctx);
        }),
        const SizedBox(height: 40),
      ]),
    )));
  }

  void _openEditShiftSheet(ShiftData shift) {
    int startMin = effectiveStartMinutes(shift) % 1440;
    int endMin = effectiveEndMinutes(shift) % 1440;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${t('edit_shift')}: ${shift.employeeName}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _timePickerField(ctx, t('start_time'), startMin, (v) => setModalState(() => startMin = v))),
          const SizedBox(width: 12),
          Expanded(child: _timePickerField(ctx, t('end_time'), endMin, (v) => setModalState(() => endMin = v))),
        ]),
        const SizedBox(height: 24),
        buildNeonButton(t('save'), () {
          final durMin = (endMin - startMin + 1440) % 1440;
          _wsDoc.collection('shifts').doc(shift.id).update({
            'timeWindow': '${fmtMinutes(startMin)} - ${fmtMinutes(endMin)}',
            'startMinutes': startMin, 'endMinutes': endMin,
            'durationHours': (durMin / 60).round(),
          });
          Navigator.pop(ctx);
        }),
        const SizedBox(height: 8),
        TextButton(onPressed: () { _wsDoc.collection('shifts').doc(shift.id).delete(); Navigator.pop(ctx); }, child: Text(t('delete'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        const SizedBox(height: 32),
      ]),
    )));
  }

  // Feature 4: non-blocking scheduler warning — true means go ahead.
  // Flags assignments on a day the employee marked unavailable, or inside
  // an approved leave range (only vacations with ISO dates can be checked).
  Future<bool> _availabilityOk(BuildContext ctx, EmployeeData emp, DateTime date) async {
    String? issue;
    final availDoc = await _wsDoc.collection('availability').doc(emp.id).get();
    if (availabilityStatus(availDoc.data(), date.weekday) == 'unavailable') issue = t('avail_warning_unavailable');
    if (issue == null) {
      for (final v in widget.vacations) {
        if (v.status != 'Approved') continue;
        if (v.employeeId != emp.id && v.employeeName != emp.name) continue;
        final s = DateTime.tryParse(v.startDate ?? ''); final e = DateTime.tryParse(v.endDate ?? '');
        if (s == null || e == null) continue;
        if (!date.isBefore(DateTime(s.year, s.month, s.day)) && !date.isAfter(DateTime(e.year, e.month, e.day))) { issue = t('avail_warning_leave'); break; }
      }
    }
    if (issue == null) return true;
    if (!ctx.mounted) return false;
    final proceed = await showDialog<bool>(context: ctx, builder: (dCtx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.orange)),
      title: Text(t('avail_warning_title'), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w900)),
      content: Text('${emp.name} $issue', style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dCtx, false), child: Text(t('cancel'), style: const TextStyle(color: Colors.white54))),
        TextButton(onPressed: () => Navigator.pop(dCtx, true), child: Text(t('proceed'), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
      ],
    ));
    return proceed ?? false;
  }

  // --- Feature 3: Shift Templates & Auto-Fill ---------------------------
  void _openTemplatesSheet() {
    final nameCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('templates'), style: const TextStyle(color: AppColors.neonCyan, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 24),
          buildNeonTextField(controller: nameCtrl, hint: t('template_name'), icon: Icons.layers_outlined),
          const SizedBox(height: 12),
          buildNeonButton(t('save_week_template'), () {
            if (_saveWeekAsTemplate(nameCtrl.text)) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.surface, content: Text(t('template_saved'), style: const TextStyle(color: Colors.white))));
            }
          }),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: StreamBuilder<QuerySnapshot>(
              stream: _wsDoc.collection('shiftTemplates').where('archived', isEqualTo: false).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
                final templates = snap.data!.docs.map((d) => ShiftTemplateData.fromFirestore(d)).toList()..sort((a, b) => a.name.compareTo(b.name));
                if (templates.isEmpty) return Padding(padding: const EdgeInsets.only(bottom: 24), child: Text(t('no_templates'), style: const TextStyle(color: Colors.white54)));
                return ListView(
                  shrinkWrap: true,
                  children: templates.map((tpl) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                    child: ListTile(
                      title: Text(tpl.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('${tpl.pattern.length} ${t('slots')}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(onPressed: () { Navigator.pop(ctx); _applyTemplate(tpl); }, child: Text(t('apply'), style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w900))),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => _wsDoc.collection('shiftTemplates').doc(tpl.id).update({'archived': true})),
                        ],
                      ),
                    ),
                  )).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ));
  }

  // Captures the visible week's shifts as an anonymous weekday+time pattern.
  bool _saveWeekAsTemplate(String name) {
    if (name.trim().isEmpty) return false;
    final pattern = <Map<String, dynamic>>[];
    for (final d in _visibleWeek) {
      for (final s in widget.shifts.where((s) => occursOn(s, d))) {
        pattern.add({'weekday': d.weekday, 'startMinutes': effectiveStartMinutes(s), 'endMinutes': effectiveEndMinutes(s) % 1440});
      }
    }
    if (pattern.isEmpty) return false;
    _wsDoc.collection('shiftTemplates').add({'name': name.trim(), 'pattern': pattern, 'archived': false, 'createdAt': DateTime.now().toIso8601String()});
    return true;
  }

  // Auto-fill: assigns each template slot to the least-loaded employee of the
  // visible week, skipping anyone already scheduled that day and preferring
  // candidates who stay under the 160h monthly overtime threshold.
  Future<void> _applyTemplate(ShiftTemplateData tpl) async {
    final week = _visibleWeek;
    final mRef = week.first;
    // Feature 4: respect availability — skip 'unavailable', prefer 'preferred'.
    final availSnap = await _wsDoc.collection('availability').get();
    final avail = {for (final d in availSnap.docs) d.id: d.data()};
    final weekHours = {for (final e in widget.employees) e.id: widget.shifts.where((s) => s.employeeId == e.id && week.any((d) => occursOn(s, d))).fold<int>(0, (a, s) => a + s.durationHours)};
    final monthHours = {for (final e in widget.employees) e.id: widget.shifts.where((s) => s.employeeId == e.id && (s.month == null || s.month == mRef.month) && (s.year == null || s.year == mRef.year)).fold<int>(0, (a, s) => a + s.durationHours)};
    final assigned = <String>{};
    final batch = FirebaseFirestore.instance.batch();
    int created = 0;

    for (final p in tpl.pattern) {
      final date = week.firstWhere((d) => d.weekday == (p['weekday'] ?? 1), orElse: () => week.first);
      final startMin = (p['startMinutes'] ?? 540) as int;
      final endMin = (p['endMinutes'] ?? 1020) as int;
      final durH = (((endMin - startMin + 1440) % 1440) / 60).round();

      final candidates = widget.employees.where((e) =>
        availabilityStatus(avail[e.id], date.weekday) != 'unavailable' &&
        !assigned.contains('${e.id}-${date.day}') &&
        !widget.shifts.any((s) => s.employeeId == e.id && occursOn(s, date))).toList();
      if (candidates.isEmpty) continue;

      final safe = candidates.where((e) => (monthHours[e.id] ?? 0) + durH <= 160).toList();
      final pool = safe.isNotEmpty ? safe : candidates;
      pool.sort((a, b) {
        final pa = availabilityStatus(avail[a.id], date.weekday) == 'preferred' ? 0 : 1;
        final pb = availabilityStatus(avail[b.id], date.weekday) == 'preferred' ? 0 : 1;
        if (pa != pb) return pa - pb;
        return (weekHours[a.id] ?? 0).compareTo(weekHours[b.id] ?? 0);
      });
      final pick = pool.first;

      batch.set(_wsDoc.collection('shifts').doc(), {
        'restaurantId': widget.workspaceId, 'employeeId': pick.id, 'employeeName': pick.name,
        'timeWindow': '${fmtMinutes(startMin)} - ${fmtMinutes(endMin)}',
        'dayOfMonth': date.day, 'month': date.month, 'year': date.year,
        'startMinutes': startMin, 'endMinutes': endMin, 'durationHours': durH,
      });
      assigned.add('${pick.id}-${date.day}');
      weekHours[pick.id] = (weekHours[pick.id] ?? 0) + durH;
      monthHours[pick.id] = (monthHours[pick.id] ?? 0) + durH;
      created++;
    }

    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.surface, content: Text('${t('template_applied')}: $created/${tpl.pattern.length}', style: const TextStyle(color: Colors.white))));
    }
  }

  // --- Tab 3: Requests (swaps + vacations) -----------------------------
  Widget _buildRequestsTab() {
    final pendingVacs = widget.vacations.where((v) => v.status == 'Pending').toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(t('requests'), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 24),
        Text(t('swaps'), style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _wsDoc.collection('swapRequests').where('status', isEqualTo: 'pending').snapshots(),
          builder: (context, swapSnap) {
            if (!swapSnap.hasData || swapSnap.data!.docs.isEmpty) return Text(t('no_requests'), style: const TextStyle(color: Colors.white54));
            return Column(
              children: swapSnap.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                // Feature 5: 'swap' (legacy default) | 'drop' | 'claim'.
                final type = data['type'] ?? 'swap';
                final requester = data['requesterName'] ?? '';
                final headline = switch (type) {
                  'drop' => '$requester ${t('wants_drop')}',
                  'claim' => '$requester ${t('volunteers_for')}',
                  _ => '$requester ${t('wants_assign')} ${data['targetName'] ?? ''}',
                };
                return Container(
                  margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withValues(alpha: 0.5))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(headline, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: buildNeonButton(t('approve'), () async {
                        WriteBatch batch = FirebaseFirestore.instance.batch();
                        batch.update(doc.reference, {'status': 'approved'});
                        final shiftRef = _wsDoc.collection('shifts').doc(data['shiftId']);
                        String msg;
                        if (type == 'drop') {
                          batch.update(shiftRef, {'employeeId': '', 'employeeName': '', 'isOpenShift': true});
                          msg = '${t('noti_drop_approved')}$requester';
                        } else if (type == 'claim') {
                          batch.update(shiftRef, {'employeeId': data['requesterId'], 'employeeName': requester, 'isOpenShift': false});
                          msg = '${t('noti_claim_approved')}$requester';
                        } else {
                          batch.update(shiftRef, {'employeeId': data['targetId'], 'employeeName': data['targetName']});
                          msg = '${t('swap_approved_for')}$requester';
                        }
                        batch.set(_wsDoc.collection('notifications').doc(), {'msg': msg, 'read': false, 'time': DateTime.now().toIso8601String(), 'targetEmployeeId': data['requesterId']});
                        await batch.commit();
                      })),
                      const SizedBox(width: 8),
                      Expanded(child: TextButton(onPressed: () => doc.reference.update({'status': 'rejected'}), child: Text(t('reject'), style: const TextStyle(color: Colors.redAccent))))
                    ])
                  ])
                );
              }).toList(),
            );
          }
        ),
        const SizedBox(height: 24),
        Text(t('vac_requests'), style: const TextStyle(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        if (pendingVacs.isEmpty) Text(t('no_requests'), style: const TextStyle(color: Colors.white54)),
        ...pendingVacs.map((v) => Container(
          margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.4))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${v.employeeName} • ${v.dates}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: buildNeonButton(t('approve'), () => _decideVacation(v, 'Approved'))),
              const SizedBox(width: 8),
              Expanded(child: TextButton(onPressed: () => _decideVacation(v, 'Denied'), child: Text(t('deny'), style: const TextStyle(color: Colors.redAccent)))),
            ]),
          ]),
        )),
      ],
    );
  }

  void _decideVacation(VacationData v, String status) {
    final noteCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: status == 'Approved' ? AppColors.neonCyan : Colors.redAccent)),
      title: Text(status == 'Approved' ? t('approve') : t('deny'), style: TextStyle(color: status == 'Approved' ? AppColors.neonCyan : Colors.redAccent, fontWeight: FontWeight.w900)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${v.employeeName} • ${v.dates}', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        buildNeonTextField(controller: noteCtrl, hint: t('reason_note'), icon: Icons.notes),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'), style: const TextStyle(color: Colors.white54))),
        TextButton(onPressed: () {
          WriteBatch batch = FirebaseFirestore.instance.batch();
          batch.update(_wsDoc.collection('vacations').doc(v.id), {'status': status, 'decisionNote': noteCtrl.text.trim()});
          batch.set(_wsDoc.collection('notifications').doc(), {'msg': '${t('vacation')} ${t(status.toLowerCase())}: ${v.employeeName}', 'read': false, 'time': DateTime.now().toIso8601String(), 'targetEmployeeId': v.employeeId});
          batch.commit();
          Navigator.pop(ctx);
        }, child: Text(status == 'Approved' ? t('approve') : t('deny'), style: TextStyle(color: status == 'Approved' ? AppColors.neonCyan : Colors.redAccent, fontWeight: FontWeight.bold))),
      ],
    ));
  }

  // --- Tab 4: Announcements --------------------------------------------
  Widget _buildAnnounceTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(t('announce'), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 24),
        buildNeonTextField(controller: _announceCtrl, hint: t('announcement_hint'), icon: Icons.campaign_outlined),
        const SizedBox(height: 16),
        buildNeonButton(t('post'), () {
          final text = _announceCtrl.text.trim();
          if (text.isEmpty) return;
          WriteBatch batch = FirebaseFirestore.instance.batch();
          batch.set(_wsDoc.collection('announcements').doc(), {'body': text, 'authorName': widget.currentManager.name, 'createdAt': DateTime.now().toIso8601String(), 'archived': false});
          batch.set(_wsDoc.collection('notifications').doc(), {'msg': '📢 $text', 'read': false, 'time': DateTime.now().toIso8601String()});
          batch.commit();
          _announceCtrl.clear();
        }),
        const SizedBox(height: 32),
        StreamBuilder<QuerySnapshot>(
          stream: _wsDoc.collection('announcements').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
            if (snap.data!.docs.isEmpty) return Text(t('no_announcements'), style: const TextStyle(color: Colors.white54));
            return Column(
              children: snap.data!.docs.map((doc) {
                final created = (doc['createdAt'] ?? '') as String;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(doc['body'], style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('${doc['authorName']} • ${created.length >= 10 ? created.substring(0, 10) : created}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ]),
                );
              }).toList(),
            );
          }
        ),
      ],
    );
  }
}
