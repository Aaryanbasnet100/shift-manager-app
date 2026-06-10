import 'package:cloud_firestore/cloud_firestore.dart';

// Lightweight audit trail: who did what, when. Fire-and-forget so it never
// blocks the UI; entries live at restaurants/{ws}/auditLog.
void logAudit(String workspaceId, String actor, String action) {
  FirebaseFirestore.instance.collection('restaurants').doc(workspaceId).collection('auditLog').add({
    'actor': actor,
    'action': action,
    'time': DateTime.now().toIso8601String(),
  });
}
