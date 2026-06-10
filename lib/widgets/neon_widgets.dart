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

Widget buildNeonButton(String text, VoidCallback onTap) {
  return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: AppColors.neonGradient, boxShadow: [BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))]), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2))));
}
