import 'package:flutter/material.dart';

// Canonical ShiftFlow design-system values, extracted verbatim from the
// original screens. Do not add new colors here without a design reason.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF090A0F);
  static const Color surface = Color(0xFF13161F);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonPurple = Color(0xFF8A2BE2);

  static const LinearGradient neonGradient = LinearGradient(colors: [neonCyan, neonPurple]);
}
