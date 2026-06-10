import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../models/models.dart';
import '../services/shift_conflict_engine.dart';
import '../theme/app_colors.dart';
import '../widgets/neon_widgets.dart';
import '../widgets/notification_drawer.dart';

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
        backgroundColor: AppColors.background, selectedItemColor: AppColors.neonCyan, unselectedItemColor: Colors.white38,
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
          IconButton(icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.neonCyan), onPressed: () => _showAddEmpForm(context))
        ]),
        const SizedBox(height: 24),
        ...widget.employees.map((emp) => Container(
          margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(emp.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('${emp.role}\nID: ${emp.username}', style: const TextStyle(color: Colors.white54)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Feature 3: Admin Shift Builder Access
                IconButton(icon: const Icon(Icons.add_task, color: AppColors.neonCyan), onPressed: () => _showAdminShiftBuilder(context, emp)),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () {
                  showDialog(context: context, builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent)),
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
    String appRole = 'employee';
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.surface, builder: (context) => StatefulBuilder(builder: (context, setModalState) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(t('add_emp'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 24), buildNeonTextField(controller: nameCtrl, hint: t('name'), icon: Icons.badge_outlined), const SizedBox(height: 12), buildNeonTextField(controller: roleCtrl, hint: t('role'), icon: Icons.work_outline), const SizedBox(height: 12), buildNeonTextField(controller: userCtrl, hint: t('user'), icon: Icons.alternate_email), const SizedBox(height: 12), buildNeonTextField(controller: passCtrl, hint: t('pass'), icon: Icons.lock_outline), const SizedBox(height: 12), DropdownButtonFormField<String>(value: appRole, dropdownColor: AppColors.surface, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: AppColors.background, prefixIcon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.neonCyan), labelText: t('access_level'), labelStyle: const TextStyle(color: Colors.white38), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: [DropdownMenuItem(value: 'employee', child: Text(t('role_employee'))), DropdownMenuItem(value: 'manager', child: Text(t('role_manager')))], onChanged: (val) { if (val != null) setModalState(() => appRole = val); }), const SizedBox(height: 24), buildNeonButton(t('save_cloud'), () { if (nameCtrl.text.isNotEmpty && userCtrl.text.isNotEmpty) { FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).collection('employees').add({'restaurantId': widget.workspaceId, 'name': nameCtrl.text, 'role': roleCtrl.text.isEmpty ? 'Staff' : roleCtrl.text, 'username': userCtrl.text.toLowerCase(), 'password': passCtrl.text, 'appRole': appRole}); Navigator.pop(context); } }), const SizedBox(height: 40)]))));
  }

  // Feature 3: Admin Shift Builder
  void _showAdminShiftBuilder(BuildContext context, EmployeeData emp) {
    final dayCtrl = TextEditingController(); final durCtrl = TextEditingController(text: '8');
    String selectedSlot = t('morning');
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.surface, builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('${t('deploy_shift')}: ${emp.name}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 24), buildNeonTextField(controller: dayCtrl, hint: t('day_of_month'), icon: Icons.calendar_today), const SizedBox(height: 12), DropdownButtonFormField<String>(value: selectedSlot, dropdownColor: AppColors.surface, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: [t('morning'), t('afternoon'), t('night')].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) { if(val != null) setModalState(() => selectedSlot = val); }), const SizedBox(height: 12), buildNeonTextField(controller: durCtrl, hint: t('duration'), icon: Icons.timer), const SizedBox(height: 24), buildNeonButton(t('deploy_shift'), () async { int day = int.tryParse(dayCtrl.text) ?? 1; if (await checkShiftConflict(ctx, widget.shifts, emp.id, day)) { FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).collection('shifts').add({'restaurantId': widget.workspaceId, 'employeeId': emp.id, 'employeeName': emp.name, 'timeWindow': selectedSlot, 'dayOfMonth': day, 'durationHours': int.tryParse(durCtrl.text) ?? 8}); Navigator.pop(ctx); } }), const SizedBox(height: 40)]))));
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
        if (widget.shifts.isEmpty) Text(t('no_shifts'), style: const TextStyle(color: Colors.white54)),
        ...widget.shifts.map((shift) => Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))), child: ListTile(title: Text(shift.employeeName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text('${shift.timeWindow} • ${t('day')}: ${shift.dayOfMonth}', style: const TextStyle(color: AppColors.neonCyan)), trailing: IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent), onPressed: () => FirebaseFirestore.instance.collection('restaurants').doc(widget.workspaceId).collection('shifts').doc(shift.id).delete())))),
      ],
    );
  }
}
