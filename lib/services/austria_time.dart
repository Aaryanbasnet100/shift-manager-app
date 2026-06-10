// Austrian local-time helpers (CET/CEST with automatic summer-time switch),
// extracted from the employee clock so dashboards can share the same "now".

bool isCEST(DateTime utcNow) {
  if (utcNow.month > 3 && utcNow.month < 10) return true;
  if (utcNow.month < 3 || utcNow.month > 10) return false;
  int previousSunday(int y, int m, int d) => d - DateTime.utc(y, m, d).weekday;
  if (utcNow.month == 3) return utcNow.day >= previousSunday(utcNow.year, 3, 31) && (utcNow.day > previousSunday(utcNow.year, 3, 31) || utcNow.hour >= 1);
  return utcNow.day < previousSunday(utcNow.year, 10, 31) || (utcNow.day == previousSunday(utcNow.year, 10, 31) && utcNow.hour < 1);
}

DateTime austriaNow() {
  final utcNow = DateTime.now().toUtc();
  return utcNow.add(Duration(hours: isCEST(utcNow) ? 2 : 1));
}
