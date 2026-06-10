import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../models/models.dart';
import '../services/austria_time.dart';
import '../services/shift_time.dart';
import '../theme/app_colors.dart';

// ==========================================
// REPORTS & ANALYTICS (Feature 9)
// Current-month scheduled vs worked hours, labor cost, per-employee
// hour bars, attendance summary, overtime and understaffing alerts.
// ==========================================
class ReportsScreen extends StatelessWidget {
  final String workspaceId;
  final List<EmployeeData> employees;
  final List<ShiftData> shifts;
  const ReportsScreen({super.key, required this.workspaceId, required this.employees, required this.shifts});

  @override
  Widget build(BuildContext context) {
    final now = austriaNow();
    final monthShifts = shifts.where((s) => (s.month == null || s.month == now.month) && (s.year == null || s.year == now.year)).toList();
    final scheduledHours = monthShifts.fold<int>(0, (a, s) => a + s.durationHours);

    // Labor cost = scheduled hours × hourly rate, per employee.
    num laborCost = 0;
    final hoursByEmp = <String, int>{};
    for (final e in employees) {
      final h = monthShifts.where((s) => s.employeeId == e.id).fold<int>(0, (a, s) => a + s.durationHours);
      hoursByEmp[e.id] = h;
      laborCost += h * e.hourlyRate;
    }
    final maxEmpHours = hoursByEmp.values.fold<int>(1, (a, b) => b > a ? b : a);
    final overtimeEmps = employees.where((e) => (hoursByEmp[e.id] ?? 0) > 160).toList();

    // Understaffing: days of the current week with no shifts at all.
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final understaffed = List.generate(7, (i) => monday.add(Duration(days: i))).where((d) => !shifts.any((s) => occursOn(s, d))).toList();

    String hm(int m) => '${m ~/ 60}${t('hours_short')} ${m % 60}${t('min_short')}';

    Widget sectionLabel(String text, {Color color = Colors.white54}) => Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );

    Widget statCard(String label, String value, {Color valueColor = Colors.white}) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(color: valueColor, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, maxLines: 2, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ]),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.neonCyan), onPressed: () => Navigator.pop(context)),
        title: Text(t('reports').toUpperCase(), style: const TextStyle(color: AppColors.neonCyan, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('restaurants').doc(workspaceId).collection('timeEntries').snapshots(),
        builder: (context, snap) {
          int workedMin = 0, lateCount = 0, earlyCount = 0;
          if (snap.hasData) {
            for (final d in snap.data!.docs) {
              final e = d.data() as Map<String, dynamic>;
              if (e['month'] != now.month || e['year'] != now.year) continue;
              final ci = DateTime.tryParse(e['clockIn'] ?? '');
              final co = DateTime.tryParse(e['clockOut'] ?? '');
              if (ci == null) continue;
              if (co != null) workedMin += co.difference(ci).inMinutes;
              final ss = e['scheduledStartMinutes'] as int?;
              final se = e['scheduledEndMinutes'] as int?;
              if (ss != null && ci.hour * 60 + ci.minute > ss + 5) lateCount++;
              if (co != null && se != null && ss != null && se > ss && co.hour * 60 + co.minute < se - 5) earlyCount++;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('${t('month_${now.month}')} ${now.year}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.7,
                children: [
                  statCard(t('scheduled_hours'), '$scheduledHours${t('hours_short')}'),
                  statCard(t('worked_hours'), hm(workedMin), valueColor: AppColors.neonCyan),
                  statCard(t('labor_cost'), '€${laborCost.toStringAsFixed(0)}', valueColor: AppColors.neonPurple),
                  statCard('${t('late_starts')} / ${t('early_leaves')}', '$lateCount / $earlyCount', valueColor: (lateCount + earlyCount) > 0 ? Colors.orange : Colors.white),
                ],
              ),
              sectionLabel(t('hours_by_employee')),
              ...employees.map((e) {
                final h = hoursByEmp[e.id] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('$h${t('hours_short')}', style: TextStyle(color: h > 160 ? Colors.redAccent : AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 8,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(4)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (h / maxEmpHours).clamp(0.0, 1.0),
                          child: Container(decoration: BoxDecoration(gradient: AppColors.neonGradient, borderRadius: BorderRadius.circular(4))),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              sectionLabel(t('overtime_alerts'), color: Colors.redAccent),
              if (overtimeEmps.isEmpty) Text(t('none'), style: const TextStyle(color: Colors.white54))
              else ...overtimeEmps.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5))),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Text('${hoursByEmp[e.id]}${t('hours_short')}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900)),
                ]),
              )),
              sectionLabel(t('understaffed_days'), color: Colors.orange),
              if (understaffed.isEmpty) Text(t('none'), style: const TextStyle(color: Colors.white54))
              else Wrap(
                spacing: 8, runSpacing: 8,
                children: understaffed.map((d) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange)),
                  child: Text('${t('wd_${d.weekday}')} ${d.day}', style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w900)),
                )).toList(),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
