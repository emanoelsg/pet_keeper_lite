import 'package:flutter/material.dart';

class AppColors {
  // Cores primárias
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);
  
  // Cores secundárias
  static const Color secondary = Color(0xFFFF9800);
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFE65100);
  
  // Cores de fundo
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  
  // Cores de texto
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  
  // Cores de status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Cores de pets por espécie
  static const Color dogColor = Color(0xFF8D6E63);
  static const Color catColor = Color(0xFF795548);
  static const Color birdColor = Color(0xFF607D8B);
  static const Color fishColor = Color(0xFF2196F3);
  static const Color otherColor = Color(0xFF9E9E9E);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
