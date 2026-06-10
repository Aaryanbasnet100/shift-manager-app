import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'i18n/strings.dart';
import 'screens/auth_gate.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ShiftFlowApp());
}

class ShiftFlowApp extends StatelessWidget {
  const ShiftFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, lang, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ShiftFlow Enterprise',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            fontFamily: 'Roboto',
            colorScheme: const ColorScheme.dark(primary: AppColors.neonCyan, secondary: AppColors.neonPurple, surface: AppColors.surface),
          ),
          // Intentionally non-const: a const child is identical across rebuilds,
          // so the language change would never propagate below MaterialApp.
          home: AuthGate(),
        );
      }
    );
  }
}
