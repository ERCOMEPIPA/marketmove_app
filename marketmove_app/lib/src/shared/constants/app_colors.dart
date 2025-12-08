import 'package:flutter/material.dart';

/// Constantes de colores para la aplicación MarketMove
class AppColors {
  // Colores primarios
  static const Color primary = Color(0xFF2563EB); // Azul moderno
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF60A5FA);
  
  // Colores secundarios
  static const Color secondary = Color(0xFF7C3AED); // Púrpura
  static const Color secondaryDark = Color(0xFF5B21B6);
  static const Color secondaryLight = Color(0xFFA78BFA);
  
  // Colores de roles
  static const Color adminColor = Color(0xFF2563EB); // Azul
  static const Color clienteColor = Color(0xFF10B981); // Verde
  static const Color superadminColor = Color(0xFF7C3AED); // Púrpura
  
  // Colores de estado
  static const Color success = Color(0xFF10B981); // Verde
  static const Color warning = Color(0xFFF59E0B); // Naranja
  static const Color error = Color(0xFFEF4444); // Rojo
  static const Color info = Color(0xFF3B82F6); // Azul claro
  
  // Colores de fondo
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  
  // Colores de borde
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  
  // Colores de gráficos
  static const Color chartBlue = Color(0xFF3B82F6);
  static const Color chartGreen = Color(0xFF10B981);
  static const Color chartRed = Color(0xFFEF4444);
  static const Color chartYellow = Color(0xFFF59E0B);
  static const Color chartPurple = Color(0xFF8B5CF6);
  static const Color chartPink = Color(0xFFEC4899);
  static const Color chartOrange = Color(0xFFF97316);
  static const Color chartTeal = Color(0xFF14B8A6);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
