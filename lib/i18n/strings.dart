import 'package:flutter/foundation.dart';

// ==========================================
// GLOBAL STATE & LOCALIZATION ENGINE
// ==========================================
final ValueNotifier<String> appLang = ValueNotifier('en');

final Map<String, Map<String, String>> dict = {
  'en': {
    'gateway': 'Enterprise Cloud Gateway', 'workspace': 'Workspace ID (e.g., mcd_01)', 'connect': 'CONNECT TO CLOUD NODE',
    'portal': 'Identity Portal', 'user': 'Username', 'pass': 'Password', 'auth': 'AUTHORIZE ACCESS',
    'shift_graph': 'Shift Graph', 'calendar': 'Calendar', 'vacation': 'Vacation', 'my_shifts': 'MY UPCOMING SHIFTS',
    'austria_time': 'Austrian Local Time', 'req_vacation': 'Request Vacation', 'self_schedule': 'Self-Schedule Shift',
    'pending': 'Pending', 'approved': 'Approved',
    // --- NEW FEATURES DICTIONARY ---
    'conflict_title': 'SHIFT CONFLICT', 'conflict_desc': 'A shift already exists on day ', 'dismiss': 'DISMISS',
    'morning': 'Morning (06:00 - 14:00)', 'afternoon': 'Afternoon (14:00 - 22:00)', 'night': 'Night (22:00 - 06:00)',
    'duration': 'Duration (Hours)', 'deploy_shift': 'EXECUTE DEPLOYMENT', 'monthly_hours': 'MONTHLY HOURS',
    'overtime': 'OVERTIME WARNING', 'request_swap': 'Request Swap', 'select_colleague': 'Select Colleague',
    'notifications': 'SYSTEM ALERTS', 'delete_emp': 'Purge Record?', 'confirm_del': 'Permanently delete staff member: ',
    'cancel': 'CANCEL', 'delete': 'PURGE', 'schedule_for': 'Schedule Day ', 'swaps': 'PENDING SWAPS', 'approve': 'APPROVE', 'reject': 'REJECT',
    'add_emp': 'REGISTER STAFF', 'role': 'Role', 'save_cloud': 'SAVE TO CLOUD', 'directory': 'Directory', 'roster': 'Master Roster', 'no_shifts': 'No active shifts.',
    'manager_prefix': 'MANAGER', 'name': 'Name', 'day_of_month': 'Day of Month (1-31)', 'day': 'Day',
    'wants_assign': 'wants to assign shift to', 'swap_approved_for': 'Swap approved for ',
    'tap_swap': 'Tap to request swap', 'no_alerts': 'No alerts.'
  },
  'de': {
    'gateway': 'Enterprise Cloud-Gateway', 'workspace': 'Arbeitsbereich-ID', 'connect': 'MIT CLOUD-KNOTEN VERBINDEN',
    'portal': 'Identitätsportal', 'user': 'Benutzername', 'pass': 'Passwort', 'auth': 'ZUGRIFF AUTORISIEREN',
    'shift_graph': 'Schichtdiagramm', 'calendar': 'Kalender', 'vacation': 'Urlaub', 'my_shifts': 'MEINE ANSTEHENDEN SCHICHTEN',
    'austria_time': 'Österreichische Ortszeit', 'req_vacation': 'Urlaub beantragen', 'self_schedule': 'Schicht eintragen',
    'pending': 'Ausstehend', 'approved': 'Genehmigt',
    // --- NEW FEATURES DICTIONARY ---
    'conflict_title': 'SCHICHTKONFLIKT', 'conflict_desc': 'Es existiert bereits eine Schicht am Tag ', 'dismiss': 'SCHLIESSEN',
    'morning': 'Morgen (06:00 - 14:00)', 'afternoon': 'Nachmittag (14:00 - 22:00)', 'night': 'Nacht (22:00 - 06:00)',
    'duration': 'Dauer (Stunden)', 'deploy_shift': 'SCHICHT ZUWEISEN', 'monthly_hours': 'MONATSSTUNDEN',
    'overtime': 'ÜBERSTUNDENWARNUNG', 'request_swap': 'Tausch anfragen', 'select_colleague': 'Kollegen auswählen',
    'notifications': 'SYSTEMWARNUNGEN', 'delete_emp': 'Akte löschen?', 'confirm_del': 'Mitarbeiter endgültig löschen: ',
    'cancel': 'ABBRECHEN', 'delete': 'LÖSCHEN', 'schedule_for': 'Planen für Tag ', 'swaps': 'AUSSTEHENDE TAUSCHANFRAGEN', 'approve': 'GENEHMIGEN', 'reject': 'ABLEHNEN',
    'add_emp': 'MITARBEITER REGISTRIEREN', 'role': 'Rolle', 'save_cloud': 'IN CLOUD SPEICHERN', 'directory': 'Verzeichnis', 'roster': 'Dienstplan', 'no_shifts': 'Keine aktiven Schichten.',
    'manager_prefix': 'MANAGER', 'name': 'Name', 'day_of_month': 'Tag des Monats (1-31)', 'day': 'Tag',
    'wants_assign': 'möchte Schicht übertragen an', 'swap_approved_for': 'Tausch genehmigt für ',
    'tap_swap': 'Tippen, um Tausch anzufragen', 'no_alerts': 'Keine Warnungen.'
  }
};

String t(String key) => dict[appLang.value]?[key] ?? key;
