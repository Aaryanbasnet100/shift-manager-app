import '../models/models.dart';

// Parses the hour range out of a stored time window string, e.g.
// 'Morning (06:00 - 14:00)' -> (start: 6, end: 14). Language-agnostic
// because it only reads the digits. Returns null for free-form values.
({int start, int end})? parseWindow(String timeWindow) {
  final match = RegExp(r'(\d{1,2}):\d{2}\s*-\s*(\d{1,2}):\d{2}').firstMatch(timeWindow);
  if (match == null) return null;
  return (start: int.parse(match.group(1)!), end: int.parse(match.group(2)!));
}

// True when the shift covers `now`. Overnight windows (22:00 - 06:00) count
// their evening portion on the scheduled day; the post-midnight spill-over
// is ignored because the schema only stores a single dayOfMonth.
bool isShiftActiveNow(ShiftData shift, DateTime now) {
  if (shift.dayOfMonth != now.day) return false;
  final w = parseWindow(shift.timeWindow);
  if (w == null) return false;
  if (w.start < w.end) return now.hour >= w.start && now.hour < w.end;
  return now.hour >= w.start;
}
