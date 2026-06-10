import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Feature 1: Dashboard stat card — gradient icon, animated count-up value,
// uppercase label. `alert` switches the accent to the warning style.
class NeonStatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool alert;
  const NeonStatCard({super.key, required this.label, required this.value, required this.icon, this.onTap, this.alert = false});

  @override
  Widget build(BuildContext context) {
    final accent = alert ? Colors.orange : AppColors.neonCyan;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: alert && value > 0 ? Colors.orange.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            alert
                ? Icon(icon, color: Colors.orange, size: 22)
                : ShaderMask(shaderCallback: (bounds) => AppColors.neonGradient.createShader(bounds), child: Icon(icon, color: Colors.white, size: 22)),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text('${v.round()}', style: TextStyle(color: alert && value > 0 ? Colors.orange : Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
            ),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }
}
