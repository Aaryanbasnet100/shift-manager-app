import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../theme/app_colors.dart';
import 'neon_widgets.dart';

// In-App Notification Center Drawer.
// `employeeId` enables targeting: docs with a targetEmployeeId are only shown
// to that person; docs without one are broadcasts (legacy behavior). Passing
// null (workspace admin) shows everything.
Widget buildNotificationDrawer(BuildContext context, String restaurantId, {String? employeeId}) {
  return Drawer(
    backgroundColor: AppColors.background,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.all(24.0), child: Text(t('notifications'), style: const TextStyle(color: AppColors.neonCyan, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5))),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).collection('notifications').orderBy('time', descending: true).limit(50).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Padding(padding: EdgeInsets.all(24), child: NeonSkeleton(rows: 4));
                final docs = snap.data!.docs.where((d) {
                  final target = (d.data() as Map<String, dynamic>)['targetEmployeeId'];
                  return target == null || employeeId == null || target == employeeId;
                }).toList();
                if (docs.isEmpty) return EmptyState(message: t('no_alerts'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    var n = docs[i];
                    bool isRead = n['read'] ?? false;
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: isRead ? Colors.white12 : AppColors.neonCyan.withValues(alpha: 0.2), radius: 6, child: isRead ? null : const SizedBox(width: 6, height: 6)),
                      title: Text(n['msg'], style: TextStyle(color: isRead ? Colors.white54 : Colors.white, fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                      onTap: () => n.reference.update({'read': true}),
                    );
                  }
                );
              }
            ),
          )
        ],
      ),
    ),
  );
}
