import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../models/models.dart';
import '../services/shift_conflict_engine.dart';
import '../theme/app_colors.dart';
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
    final screens = [_buildTeamTab(), _buildScheduleTab(), _buildRequestsTab(), _buildAnnounceTab()];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        title: Text('${t('manager_prefix')}: ${widget.restaurantName}', style: const TextStyle(color: AppColors.neonCyan, fontSize: 14, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(icon: const Badge(backgroundColor: AppColors.neonCyan, child: Icon(Icons.notifications_none, color: Colors.white54)), onPressed: () => Scaffold.of(context).openEndDrawer()),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white54), onPressed: widget.onLogout)
        ]
      ),
      endDrawer: buildNotificationDrawer(context, widget.workspaceId),
      body: screens[_tabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex, onTap: (i) => setState(() => _tabIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background, selectedItemColor: AppColors.neonCyan, unselectedItemColor: Colors.white38,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.groups_2), label: t('my_team')),
          BottomNavigationBarItem(icon: const Icon(Icons.calendar_view_week), label: t('schedule')),
          BottomNavigationBarItem(icon: const Icon(Icons.how_to_reg), label: t('requests')),
          BottomNavigationBarItem(icon: const Icon(Icons.campaign), label: t('announce')),
        ],
      ),
    );
  }

  // --- Tab 1: My Team -------------------------------------------------
  Widget _buildTeamTab() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    // Schema stores dayOfMonth only, so the week is matched within the current month.
    final weekDayNums = List.generate(7, (i) => monday.add(Duration(days: i))).where((d) => d.month == now.month).map((d) => d.day).toSet();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(t('my_team'), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 24),
        ...widget.employees.map((emp) {
          final hours = widget.shifts.where((s) => s.employeeId == emp.id && weekDayNums.contains(s.dayOfMonth)).fold<int>(0, (a, s) => a + s.durationHours);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

  // --- Tab 2: Schedule (week view + shift CRUD) ------------------------
  Widget _buildScheduleTab() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1)).add(Duration(days: _weekOffset * 7));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(t('schedule'), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
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
          final dayShifts = widget.shifts.where((s) => s.dayOfMonth == d.day).toList();
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
                    IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.neonCyan, size: 20), onPressed: () => _openCreateShiftSheet(d.day)),
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
                        Expanded(child: Text('${s.employeeName} • ${s.timeWindow}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12))),
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

  void _openCreateShiftSheet(int day) {
    if (widget.employees.isEmpty) return;
    String empId = widget.employees.first.id;
    String slot = t('morning');
    final durCtrl = TextEditingController(text: '8');
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${t('schedule_for')}$day', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(value: empId, dropdownColor: AppColors.surface, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: widget.employees.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(), onChanged: (val) { if (val != null) setModalState(() => empId = val); }),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: slot, dropdownColor: AppColors.surface, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: [t('morning'), t('afternoon'), t('night')].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) { if (val != null) setModalState(() => slot = val); }),
        const SizedBox(height: 12),
        buildNeonTextField(controller: durCtrl, hint: t('duration'), icon: Icons.timer),
        const SizedBox(height: 24),
        buildNeonButton(t('deploy_shift'), () async {
          final emp = widget.employees.firstWhere((e) => e.id == empId);
          if (await checkShiftConflict(ctx, widget.shifts, empId, day)) {
            _wsDoc.collection('shifts').add({'restaurantId': widget.workspaceId, 'employeeId': emp.id, 'employeeName': emp.name, 'timeWindow': slot, 'dayOfMonth': day, 'durationHours': int.tryParse(durCtrl.text) ?? 8});
            Navigator.pop(ctx);
          }
        }),
        const SizedBox(height: 40),
      ]),
    )));
  }

  void _openEditShiftSheet(ShiftData shift) {
    final slots = [t('morning'), t('afternoon'), t('night')];
    // Stored value may be in the other language — fall back so the dropdown never crashes.
    String slot = slots.contains(shift.timeWindow) ? shift.timeWindow : slots.first;
    final durCtrl = TextEditingController(text: '${shift.durationHours}');
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${t('edit_shift')}: ${shift.employeeName}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(value: slot, dropdownColor: AppColors.surface, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: slots.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) { if (val != null) setModalState(() => slot = val); }),
        const SizedBox(height: 12),
        buildNeonTextField(controller: durCtrl, hint: t('duration'), icon: Icons.timer),
        const SizedBox(height: 24),
        buildNeonButton(t('save'), () {
          _wsDoc.collection('shifts').doc(shift.id).update({'timeWindow': slot, 'durationHours': int.tryParse(durCtrl.text) ?? shift.durationHours});
          Navigator.pop(ctx);
        }),
        const SizedBox(height: 8),
        TextButton(onPressed: () { _wsDoc.collection('shifts').doc(shift.id).delete(); Navigator.pop(ctx); }, child: Text(t('delete'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        const SizedBox(height: 32),
      ]),
    )));
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
              children: swapSnap.data!.docs.map((doc) => Container(
                margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withValues(alpha: 0.5))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${doc['requesterName']} ${t('wants_assign')} ${doc['targetName']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: buildNeonButton(t('approve'), () async {
                      WriteBatch batch = FirebaseFirestore.instance.batch();
                      batch.update(doc.reference, {'status': 'approved'});
                      batch.update(_wsDoc.collection('shifts').doc(doc['shiftId']), {'employeeId': doc['targetId'], 'employeeName': doc['targetName']});
                      batch.set(_wsDoc.collection('notifications').doc(), {'msg': '${t('swap_approved_for')}${doc['requesterName']}', 'read': false, 'time': DateTime.now().toIso8601String()});
                      await batch.commit();
                    })),
                    const SizedBox(width: 8),
                    Expanded(child: TextButton(onPressed: () => doc.reference.update({'status': 'rejected'}), child: Text(t('reject'), style: const TextStyle(color: Colors.redAccent))))
                  ])
                ])
              )).toList(),
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
          batch.set(_wsDoc.collection('notifications').doc(), {'msg': '${t('vacation')} ${t(status.toLowerCase())}: ${v.employeeName}', 'read': false, 'time': DateTime.now().toIso8601String()});
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
