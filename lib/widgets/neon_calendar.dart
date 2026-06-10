import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

// Issue 3: Neon design-system calendar.
// Renders a month grid with a Monday-first weekday header, neon month
// navigation, cyan-highlighted shift days, a gradient-filled selected day
// and a small time pill inside each day that has a shift.
class NeonCalendar extends StatefulWidget {
  final List<ShiftData> shifts;
  // Null = read-only calendar (plain employees); tapping only selects.
  final void Function(DateTime date)? onDayTap;
  const NeonCalendar({super.key, required this.shifts, this.onDayTap});

  @override
  State<NeonCalendar> createState() => _NeonCalendarState();
}

class _NeonCalendarState extends State<NeonCalendar> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int? _selectedDay;

  void _changeMonth(int delta) => setState(() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    _selectedDay = null;
  });

  // 'Morning (06:00 - 14:00)' -> '06-14'; falls back to the first word.
  String _pillLabel(String timeWindow) {
    final match = RegExp(r'(\d{2}):\d{2}\s*-\s*(\d{2}):\d{2}').firstMatch(timeWindow);
    if (match != null) return '${match.group(1)}-${match.group(2)}';
    return timeWindow.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingBlanks = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday - 1;
    // Schedule v2: dated shifts only show in their own month; legacy shifts
    // (null month/year) keep appearing in every month.
    final monthShifts = widget.shifts.where((s) => (s.month == null || s.month == _visibleMonth.month) && (s.year == null || s.year == _visibleMonth.year)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left_rounded, color: AppColors.neonCyan, size: 28), onPressed: () => _changeMonth(-1)),
              Text('${t('month_${_visibleMonth.month}')} ${_visibleMonth.year}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              IconButton(icon: const Icon(Icons.chevron_right_rounded, color: AppColors.neonCyan, size: 28), onPressed: () => _changeMonth(1)),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: List.generate(7, (i) => Expanded(child: Center(child: Text(t('wd_${i + 1}'), style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)))))),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 6, mainAxisSpacing: 6, childAspectRatio: 0.8),
            itemCount: leadingBlanks + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();
              final day = index - leadingBlanks + 1;
              final dayShifts = monthShifts.where((s) => s.dayOfMonth == day).toList();
              final hasShift = dayShifts.isNotEmpty;
              final isSelected = _selectedDay == day;

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  setState(() => _selectedDay = day);
                  widget.onDayTap?.call(DateTime(_visibleMonth.year, _visibleMonth.month, day));
                },
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.neonGradient : null,
                    color: isSelected ? null : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: hasShift && !isSelected ? AppColors.neonCyan : Colors.white.withValues(alpha: 0.05)),
                    boxShadow: hasShift && !isSelected ? [BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.15), blurRadius: 8)] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$day', style: TextStyle(color: isSelected || hasShift ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                      if (hasShift)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.neonPurple.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isSelected ? Colors.white38 : AppColors.neonPurple),
                            ),
                            child: Text(_pillLabel(dayShifts.first.timeWindow), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
