import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../theme/app_colors.dart';
import '../widgets/neon_widgets.dart';

class WorkspaceGateScreen extends StatelessWidget {
  final Function(String) onVerify;
  WorkspaceGateScreen({super.key, required this.onVerify});
  final _workspaceCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LanguageToggle(),
              const Spacer(),
              ShaderMask(shaderCallback: (bounds) => AppColors.neonGradient.createShader(bounds), child: const Icon(Icons.waves_rounded, size: 64, color: Colors.white)),
              const SizedBox(height: 24),
              const Text('ShiftFlow', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1)),
              Text(t('gateway'), style: const TextStyle(color: AppColors.neonCyan, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              const SizedBox(height: 48),
              buildNeonTextField(controller: _workspaceCtrl, hint: t('workspace'), icon: Icons.hub_outlined),
              const SizedBox(height: 32),
              buildNeonButton(t('connect'), () => onVerify(_workspaceCtrl.text.trim())),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
