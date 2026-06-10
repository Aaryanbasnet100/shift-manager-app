import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../theme/app_colors.dart';

// ==========================================
// SHARED UI COMPONENTS & HELPERS
// ==========================================
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});
  @override
  Widget build(BuildContext context) {
    // Listens to appLang directly so the toggle updates even when an ancestor
    // skips rebuilding (e.g. this widget is instantiated as const).
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, lang, _) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: () => appLang.value = 'en', child: Text('EN', style: TextStyle(color: lang == 'en' ? AppColors.neonCyan : Colors.white38, fontWeight: FontWeight.bold))),
          const Text('|', style: TextStyle(color: Colors.white38)),
          TextButton(onPressed: () => appLang.value = 'de', child: Text('DE', style: TextStyle(color: lang == 'de' ? AppColors.neonCyan : Colors.white38, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

Widget buildNeonTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
  return Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.1)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))]), child: TextField(controller: controller, obscureText: isPassword, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), prefixIcon: Icon(icon, color: AppColors.neonCyan))));
}

// Consistent floating feedback for writes — every mutation should call this.
void showNeonToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    backgroundColor: AppColors.surface,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.4))),
    content: Text(msg, style: const TextStyle(color: Colors.white)),
  ));
}

// Branded empty state: wave logo + message.
class EmptyState extends StatelessWidget {
  final String message;
  const EmptyState({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          ShaderMask(shaderCallback: (b) => AppColors.neonGradient.createShader(b), child: const Icon(Icons.waves_rounded, size: 40, color: Colors.white)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

// Pulsing placeholder rows shown while a stream is still connecting.
class NeonSkeleton extends StatefulWidget {
  final int rows;
  const NeonSkeleton({super.key, this.rows = 3});
  @override
  State<NeonSkeleton> createState() => _NeonSkeletonState();
}

class _NeonSkeletonState extends State<NeonSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 0.8).animate(_ctrl),
      child: Column(
        children: List.generate(widget.rows, (_) => Container(
          height: 52,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
        )),
      ),
    );
  }
}

Widget buildNeonButton(String text, VoidCallback onTap) {
  return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: AppColors.neonGradient, boxShadow: [BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))]), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2))));
}
