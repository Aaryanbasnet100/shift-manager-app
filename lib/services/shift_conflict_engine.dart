import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

// Feature 1: Smart Shift Conflict Engine
Future<bool> checkShiftConflict(BuildContext context, List<ShiftData> existingShifts, String employeeId, int dayOfMonth) async {
  bool hasConflict = existingShifts.any((s) => s.employeeId == employeeId && s.dayOfMonth == dayOfMonth);
  if (hasConflict) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent)),
        title: Text(t('conflict_title'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900)),
        content: Text('${t('conflict_desc')}$dayOfMonth.', style: const TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('dismiss'), style: const TextStyle(color: Colors.redAccent)))],
      )
    );
    return false;
  }
  return true;
}
