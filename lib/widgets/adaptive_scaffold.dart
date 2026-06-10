import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AdaptiveNavItem {
  final IconData icon;
  final String label;
  const AdaptiveNavItem(this.icon, this.label);
}

// Phone (<900px): the familiar BottomNavigationBar.
// Desktop (>=900px): a NavigationRail sidebar with the wave logo, and the
// content centered at a readable max width — SaaS-style.
class AdaptiveNavScaffold extends StatelessWidget {
  final PreferredSizeWidget appBar;
  final Widget? endDrawer;
  final List<AdaptiveNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget body;
  const AdaptiveNavScaffold({super.key, required this.appBar, this.endDrawer, required this.items, required this.currentIndex, required this.onTap, required this.body});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    if (!wide) {
      return Scaffold(
        appBar: appBar,
        endDrawer: endDrawer,
        body: body,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex, onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.background, selectedItemColor: AppColors.neonCyan, unselectedItemColor: Colors.white38,
          items: items.map((i) => BottomNavigationBarItem(icon: Icon(i.icon), label: i.label)).toList(),
        ),
      );
    }
    return Scaffold(
      appBar: appBar,
      endDrawer: endDrawer,
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: AppColors.background,
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            labelType: NavigationRailLabelType.all,
            indicatorColor: AppColors.neonCyan.withValues(alpha: 0.15),
            selectedIconTheme: const IconThemeData(color: AppColors.neonCyan),
            unselectedIconTheme: const IconThemeData(color: Colors.white38),
            selectedLabelTextStyle: const TextStyle(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.w900),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white38, fontSize: 11),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ShaderMask(shaderCallback: (b) => AppColors.neonGradient.createShader(b), child: const Icon(Icons.waves_rounded, color: Colors.white, size: 28)),
            ),
            destinations: items.map((i) => NavigationRailDestination(icon: Icon(i.icon), label: Text(i.label))).toList(),
          ),
          Container(width: 1, color: Colors.white.withValues(alpha: 0.06)),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: body),
            ),
          ),
        ],
      ),
    );
  }
}
