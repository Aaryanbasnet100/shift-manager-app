import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../models/models.dart';
import '../services/audit.dart';
import '../services/austria_time.dart';
import '../services/password.dart';
import '../services/shift_conflict_engine.dart';
import '../services/shift_time.dart';
import '../theme/app_colors.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/neon_widgets.dart';
import '../widgets/notification_bell.dart';
import '../widgets/notification_drawer.dart';
import 'reports_screen.dart';

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
  // Feature 12: workspace settings (compliance rules + locations).
  final _maxDayCtrl = TextEditingController();
  final _maxConsecCtrl = TextEditingController();
  final _minRestCtrl = TextEditingController();
  final _locNameCtrl = TextEditingController();
  bool _settingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _maxDayCtrl.dispose(); _maxConsecCtrl.dispose(); _minRestCtrl.dispose(); _locNameCtrl.dispose();
    super.dispose();
  }

  void _loadSettings() async {
    final doc = await FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).get();
    final s = (doc.data()?['settings'] as Map<String, dynamic>?) ?? {};
    _maxDayCtrl.text = '${s['maxHoursPerDay'] ?? 10}';
    _maxConsecCtrl.text = '${s['maxConsecutiveDays'] ?? 6}';
    _minRestCtrl.text = '${s['minRestHours'] ?? 11}';
    if (mounted) setState(() => _settingsLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [_buildStaffTab(), _buildRosterTab(), _buildSettingsTab()];
    return AdaptiveNavScaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        title: Text('${t('manager_prefix')}: ${widget.restaurantName}', style: const TextStyle(color: AppColors.neonCyan, fontSize: 14, fontWeight: FontWeight.w900)),
        actions: [
          // Feature 9: reports & analytics
          IconButton(icon: const Icon(Icons.insights, color: AppColors.neonCyan), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsScreen(workspaceId: widget.workspaceId, employees: widget.employees, shifts: widget.shifts)))),
          NotificationBell(restaurantId: widget.workspaceId),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white54), onPressed: widget.onLogout)
        ]
      ),
      endDrawer: buildNotificationDrawer(context, widget.workspaceId),
      body: screens[_tabIndex],
      currentIndex: _tabIndex,
      onTap: (i) => setState(() => _tabIndex = i),
      items: [
        AdaptiveNavItem(Icons.groups_2, t('directory')),
        AdaptiveNavItem(Icons.calendar_view_week, t('roster')),
        AdaptiveNavItem(Icons.settings_outlined, t('settings')),
      ],
    );
  }

  // Feature 8: Employee Management Panel
  Widget _buildStaffTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(t('directory'), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          IconButton(icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.neonCyan), onPressed: () => _showAddEmpForm(context))
        ]),
        const SizedBox(height: 24),
        // Onboarding: a fresh workspace starts here.
        if (widget.employees.isEmpty) ...[
          EmptyState(message: t('onboard_hint')),
          const SizedBox(height: 16),
          buildNeonButton(t('add_emp'), () => _showAddEmpForm(context)),
        ],
        ...widget.employees.map((emp) => Container(
          margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(emp.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('${emp.role}${emp.hourlyRate > 0 ? ' • €${emp.hourlyRate}/h' : ''}\nID: ${emp.username}${emp.email != null && emp.email!.isNotEmpty ? ' • ${emp.email}' : ''}', style: const TextStyle(color: Colors.white54)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Feature 3: Admin Shift Builder Access
                IconButton(icon: const Icon(Icons.add_task, color: AppColors.neonCyan), onPressed: () => _showAdminShiftBuilder(context, emp)),
                // Admin password reset — hashed passwords can't be read back,
                // so this sets a new one for a locked-out staff member.
                IconButton(icon: const Icon(Icons.key_outlined, color: Colors.amber), onPressed: () => _showResetPasswordForm(context, emp)),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () {
                  showDialog(context: context, builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent)),
                    title: Text(t('delete_emp'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    content: Text('${t('confirm_del')}${emp.name}?', style: const TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'), style: const TextStyle(color: Colors.white54))),
                      TextButton(onPressed: () {
                        // Soft-delete: the record stays in Firestore but the
                        // person disappears from the app and can't log in.
                        FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).collection('employees').doc(emp.id).update({'archived': true});
                        logAudit(widget.workspaceId, 'admin', 'archived employee ${emp.name}');
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
    final emailCtrl = TextEditingController(); final rateCtrl = TextEditingController();
    String appRole = 'employee';
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.surface, builder: (context) => StatefulBuilder(builder: (context, setModalState) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(t('add_emp'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 24), buildNeonTextField(controller: nameCtrl, hint: t('name'), icon: Icons.badge_outlined), const SizedBox(height: 12), buildNeonTextField(controller: roleCtrl, hint: t('role'), icon: Icons.work_outline), const SizedBox(height: 12), buildNeonTextField(controller: userCtrl, hint: t('user'), icon: Icons.alternate_email), const SizedBox(height: 12), buildNeonTextField(controller: passCtrl, hint: t('pass'), icon: Icons.lock_outline), const SizedBox(height: 12), buildNeonTextField(controller: emailCtrl, hint: t('email'), icon: Icons.mail_outline), const SizedBox(height: 12), buildNeonTextField(controller: rateCtrl, hint: t('hourly_rate'), icon: Icons.euro), const SizedBox(height: 12), DropdownButtonFormField<String>(value: appRole, dropdownColor: AppColors.surface, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: AppColors.background, prefixIcon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.neonCyan), labelText: t('access_level'), labelStyle: const TextStyle(color: Colors.white38), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: [DropdownMenuItem(value: 'employee', child: Text(t('role_employee'))), DropdownMenuItem(value: 'manager', child: Text(t('role_manager')))], onChanged: (val) { if (val != null) setModalState(() => appRole = val); }), const SizedBox(height: 24), buildNeonButton(t('save_cloud'), () { final email = emailCtrl.text.trim(); if (nameCtrl.text.trim().isEmpty || userCtrl.text.trim().length < 3 || passCtrl.text.length < 4 || (email.isNotEmpty && !email.contains('@'))) { showNeonToast(context, t('invalid_input')); return; } { FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).collection('employees').add({'restaurantId': widget.workspaceId, 'name': nameCtrl.text, 'role': roleCtrl.text.isEmpty ? 'Staff' : roleCtrl.text, 'username': userCtrl.text.toLowerCase(), 'password': encodePassword(passCtrl.text, '${widget.workspaceId}:${userCtrl.text.toLowerCase()}'), 'appRole': appRole, 'email': emailCtrl.text.trim(), 'hourlyRate': num.tryParse(rateCtrl.text) ?? 0, 'archived': false}); logAudit(widget.workspaceId, 'admin', 'registered employee ${nameCtrl.text} ($appRole)'); Navigator.pop(context); showNeonToast(context, t('saved')); } }), const SizedBox(height: 40)]))));
  }

  // Admin password reset: sets a fresh salted hash for the given employee.
  void _showResetPasswordForm(BuildContext context, EmployeeData emp) {
    final passCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${t('reset_password')}: ${emp.name}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('@${emp.username}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 24),
        buildNeonTextField(controller: passCtrl, hint: t('new_pass'), icon: Icons.lock_outline, isPassword: true),
        const SizedBox(height: 16),
        buildNeonButton(t('save'), () {
          if (passCtrl.text.length < 4) { showNeonToast(context, t('invalid_input')); return; }
          FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).collection('employees').doc(emp.id).update({'password': encodePassword(passCtrl.text, '${widget.workspaceId}:${emp.username}')});
          logAudit(widget.workspaceId, 'admin', 'reset password for ${emp.name}');
          Navigator.pop(ctx);
          showNeonToast(context, t('saved'));
        }),
        const SizedBox(height: 40),
      ]),
    ));
  }

  // Feature 3: Admin Shift Builder
  void _showAdminShiftBuilder(BuildContext context, EmployeeData emp) {
    final dayCtrl = TextEditingController(); final durCtrl = TextEditingController(text: '8');
    String selectedSlot = t('morning');
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.surface, builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('${t('deploy_shift')}: ${emp.name}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 24), buildNeonTextField(controller: dayCtrl, hint: t('day_of_month'), icon: Icons.calendar_today), const SizedBox(height: 12), DropdownButtonFormField<String>(value: selectedSlot, dropdownColor: AppColors.surface, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: [t('morning'), t('afternoon'), t('night')].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) { if(val != null) setModalState(() => selectedSlot = val); }), const SizedBox(height: 12), buildNeonTextField(controller: durCtrl, hint: t('duration'), icon: Icons.timer), const SizedBox(height: 24), buildNeonButton(t('deploy_shift'), () async { int day = int.tryParse(dayCtrl.text) ?? 1; final nowA = austriaNow(); final date = DateTime(nowA.year, nowA.month, day); if (await checkShiftConflict(ctx, widget.shifts, emp.id, date)) { final w = parseWindow(selectedSlot); FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).collection('shifts').add({'restaurantId': widget.workspaceId, 'employeeId': emp.id, 'employeeName': emp.name, 'timeWindow': selectedSlot, 'dayOfMonth': day, 'month': date.month, 'year': date.year, if (w != null) 'startMinutes': w.start * 60, if (w != null) 'endMinutes': w.end * 60, 'durationHours': int.tryParse(durCtrl.text) ?? 8}); Navigator.pop(ctx); } }), const SizedBox(height: 40)]))));
  }

  // Feature 12: workspace settings — compliance rules + locations.
  Widget _buildSettingsTab() {
    final wsRef = FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(t('settings'), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 24),
        Text(t('compliance_rules'), style: const TextStyle(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        if (!_settingsLoaded) const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
        else ...[
          buildNeonTextField(controller: _maxDayCtrl, hint: t('max_hours_day'), icon: Icons.timelapse),
          const SizedBox(height: 12),
          buildNeonTextField(controller: _maxConsecCtrl, hint: t('max_consec_days'), icon: Icons.date_range),
          const SizedBox(height: 12),
          buildNeonTextField(controller: _minRestCtrl, hint: t('min_rest_hours'), icon: Icons.hotel),
          const SizedBox(height: 16),
          buildNeonButton(t('save'), () {
            wsRef.set({'settings': {
              'maxHoursPerDay': num.tryParse(_maxDayCtrl.text) ?? 10,
              'maxConsecutiveDays': num.tryParse(_maxConsecCtrl.text) ?? 6,
              'minRestHours': num.tryParse(_minRestCtrl.text) ?? 11,
            }}, SetOptions(merge: true));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.surface, content: Text(t('saved'), style: const TextStyle(color: Colors.white))));
          }),
        ],
        const SizedBox(height: 32),
        Text(t('locations'), style: const TextStyle(color: AppColors.neonPurple, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: wsRef.collection('locations').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            final locations = snap.data!.docs.map((d) => LocationData.fromFirestore(d)).where((l) => !l.archived).toList();
            return Column(
              children: locations.map((l) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                child: ListTile(
                  leading: const Icon(Icons.place_outlined, color: AppColors.neonPurple),
                  title: Text(l.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => wsRef.collection('locations').doc(l.id).update({'archived': true})),
                ),
              )).toList(),
            );
          },
        ),
        const SizedBox(height: 8),
        buildNeonTextField(controller: _locNameCtrl, hint: t('location_name'), icon: Icons.add_location_alt_outlined),
        const SizedBox(height: 12),
        buildNeonButton(t('add_location'), () {
          if (_locNameCtrl.text.trim().isEmpty) return;
          wsRef.collection('locations').add({'name': _locNameCtrl.text.trim(), 'archived': false});
          logAudit(widget.workspaceId, 'admin', 'added location ${_locNameCtrl.text.trim()}');
          _locNameCtrl.clear();
        }),
        const SizedBox(height: 32),
        // Feature: audit trail of every schedule/staff mutation.
        Text(t('audit_log'), style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: wsRef.collection('auditLog').orderBy('time', descending: true).limit(50).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const NeonSkeleton(rows: 3);
            if (snap.data!.docs.isEmpty) return Text(t('none'), style: const TextStyle(color: Colors.white54));
            return Column(
              children: snap.data!.docs.map((d) {
                final e = d.data() as Map<String, dynamic>;
                final time = (e['time'] ?? '') as String;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                  child: Row(
                    children: [
                      Expanded(child: Text('${e['actor'] ?? '?'} — ${e['action'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 12))),
                      Text(time.length >= 16 ? time.substring(0, 16).replaceAll('T', ' ') : time, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 40),
      ],
    );
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
                  margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withValues(alpha: 0.5))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${doc['requesterName']} ${t('wants_assign')} ${doc['targetName']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: buildNeonButton(t('approve'), () async {
                        WriteBatch batch = FirebaseFirestore.instance.batch();
                        batch.update(doc.reference, {'status': 'approved'});
                        batch.update(FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).collection('shifts').doc(doc['shiftId']), {'employeeId': doc['targetId'], 'employeeName': doc['targetName']});
                        batch.set(FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).collection('notifications').doc(), {'msg': '${t('swap_approved_for')}${doc['requesterName']}', 'read': false, 'time': DateTime.now().toIso8601String()});
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
        if (widget.shifts.isEmpty) EmptyState(message: t('no_shifts')),
        ...widget.shifts.map((shift) => Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))), child: ListTile(title: Text(shift.employeeName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text('${shift.timeWindow} • ${t('day')}: ${shift.dayOfMonth}', style: const TextStyle(color: AppColors.neonCyan)), trailing: IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent), onPressed: () => FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).collection('shifts').doc(shift.id).delete())))),
      ],
    );
  }
}
