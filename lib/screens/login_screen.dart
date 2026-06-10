import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../theme/app_colors.dart';
import '../widgets/neon_widgets.dart';

class LoginScreen extends StatelessWidget {
  final String restaurantName; final Function(String, String) onLogin; final VoidCallback onBack;
  LoginScreen({super.key, required this.restaurantName, required this.onLogin, required this.onBack});
  final _userCtrl = TextEditingController(); final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.neonCyan), onPressed: onBack)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LanguageToggle(),
              Text(restaurantName.toUpperCase(), style: const TextStyle(color: AppColors.neonPurple, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
              Text(t('portal'), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
              const SizedBox(height: 48),
              buildNeonTextField(controller: _userCtrl, hint: t('user'), icon: Icons.person_outline),
              const SizedBox(height: 16),
              buildNeonTextField(controller: _passCtrl, hint: t('pass'), icon: Icons.lock_outline, isPassword: true),
              const SizedBox(height: 40),
              buildNeonButton(t('auth'), () => onLogin(_userCtrl.text, _passCtrl.text)),
            ],
          ),
        ),
      ),
    );
  }
}
