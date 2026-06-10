import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Bell with a live unread count: badge hidden at zero, shows the number
// of unread notifications visible to this user (broadcasts + targeted).
class NotificationBell extends StatelessWidget {
  final String restaurantId;
  final String? employeeId;
  const NotificationBell({super.key, required this.restaurantId, this.employeeId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).collection('notifications').where('read', isEqualTo: false).snapshots(),
      builder: (context, snap) {
        int count = 0;
        if (snap.hasData) {
          count = snap.data!.docs.where((d) {
            final target = (d.data() as Map<String, dynamic>)['targetEmployeeId'];
            return target == null || employeeId == null || target == employeeId;
          }).length;
        }
        // Builder: Scaffold.of needs a context below the Scaffold.
        return Builder(builder: (ctx) => IconButton(
          icon: Badge(
            isLabelVisible: count > 0,
            backgroundColor: AppColors.neonCyan,
            label: Text('$count', style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
            child: const Icon(Icons.notifications_none, color: Colors.white54),
          ),
          onPressed: () => Scaffold.of(ctx).openEndDrawer(),
        ));
      },
    );
  }
}
