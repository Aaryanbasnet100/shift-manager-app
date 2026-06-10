import '../models/models.dart';

// Parses the hour range out of a stored time window string, e.g.
// 'Morning (06:00 - 14:00)' -> (start: 6, end: 14). Language-agnostic
// because it only reads the digits. Returns null for free-form values.
({int start, int end})? parseWindow(String timeWindow) {
  final match = RegExp(r'(\d{1,2}):\d{2}\s*-\s*(\d{1,2}):\d{2}').firstMatch(timeWindow);
  if (match == null) return null;
  return (start: int.parse(match.group(1)!), end: int.parse(match.group(2)!));
}

// Minutes-since-midnight, preferring the explicit v2 fields and falling
// back to the parsed timeWindow for legacy shifts.
int effectiveStartMinutes(ShiftData s) => s.startMinutes ?? (parseWindow(s.timeWindow)?.start ?? 0) * 60;
int effectiveEndMinutes(ShiftData s) => s.endMinutes ?? (parseWindow(s.timeWindow)?.end ?? 24) * 60;

// Does this shift fall on the given calendar date? Legacy shifts have no
// month/year and therefore match the day number in every month.
bool occursOn(ShiftData s, DateTime date) =>
    s.dayOfMonth == date.day && (s.month == null || s.month == date.month) && (s.year == null || s.year == date.year);

// True when the shift covers `now`. Overnight windows (e.g. 22:00 - 06:00)
// count their evening portion on the scheduled day; the post-midnight
// spill-over is ignored because the schema keys shifts to a single day.
bool isShiftActiveNow(ShiftData shift, DateTime now) {
  if (!occursOn(shift, now)) return false;
  final start = effectiveStartMinutes(shift);
  final end = effectiveEndMinutes(shift);
  final nowMin = now.hour * 60 + now.minute;
  if (start < end) return nowMin >= start && nowMin < end;
  return nowMin >= start;
}

String fmtMinutes(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
