import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ==========================================
// SUPER ADMIN (FOUNDER GOD MODE)
// ==========================================
class SuperAdminShell extends StatelessWidget {
  final VoidCallback onLogout;
  const SuperAdminShell({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('FOUNDER TERMINAL', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [IconButton(icon: const Icon(Icons.power_settings_new, color: Colors.white54), onPressed: onLogout)],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('restaurants').get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          final clients = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3))),
                child: ExpansionTile(
                  title: Text(client['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('ID: ${client.id} | Admin Pass: ${client['adminPassword']}', style: const TextStyle(color: Colors.white54)),
                  iconColor: Colors.redAccent, collapsedIconColor: Colors.redAccent,
                  children: [
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('restaurants').doc(client.id).collection('employees').get(),
                      builder: (ctx, empSnap) {
                        if (!empSnap.hasData) return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
                        return Column(
                          children: empSnap.data!.docs.map((doc) => ListTile(
                            leading: const Icon(Icons.person, color: Colors.white38),
                            title: Text(doc['name'], style: const TextStyle(color: Colors.white)),
                            subtitle: Text('User: ${doc['username']} | Pass: ${doc['password']}', style: const TextStyle(color: AppColors.neonCyan, fontFamily: 'monospace')),
                          )).toList(),
                        );
                      }
                    )
                  ],
                ),
              );
            },
          );
        }
      ),
    );
  }
}
