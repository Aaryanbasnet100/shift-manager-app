// Feature 4: weekly availability.
// Stored per employee at restaurants/{ws}/availability/{employeeId} as
// {'wd1': 'available'|'preferred'|'unavailable', ... 'wd7': ...}.
// A missing doc or key means available — existing staff need no setup.

const availabilityStates = ['available', 'preferred', 'unavailable'];

String availabilityStatus(Map<String, dynamic>? data, int weekday) => (data?['wd$weekday'] as String?) ?? 'available';
