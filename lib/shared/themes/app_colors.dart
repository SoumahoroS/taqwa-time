import 'package:flutter/material.dart';

class AppColors {
  // ── Brand Colors (invariants across themes) ──
  static const Color primary = Color(0xFF1E8C72);
  static const Color primaryLight = Color(0xFF4DB89E);
  static const Color primaryDark = Color(0xFF14664F);
  static const Color secondary = Color(0xFF1D3E5F);
  static const Color secondaryLight = Color(0xFF2A5A8A);
  static const Color accent = Color(0xFFD4A76A);
  static const Color accentLight = Color(0xFFE8C99A);
  static const Color alert = Color(0xFFC75D55);
  static const Color alertLight = Color(0xFFE88A83);
  static const Color success = Color(0xFF2ECC71);

  // ── Light Theme ──
  static const Color lightBackground = Color(0xFFF0EDE5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF1A1A2E);
  static const Color lightOnSurface = Color(0xFF1D3E5F);
  static const Color lightOnSurfaceVariant = Color(0xFF5A6B7D);

  // Light Glass
  static const Color lightGlassTint = Color(0x33FFFFFF);
  static const Color lightGlassBorder = Color(0x40FFFFFF);
  static const Color lightGlassShadow = Color(0x1A000000);

  // ── Dark Theme ──
  static const Color darkBackground = Color(0xFF0B1622);
  static const Color darkSurface = Color(0xFF132234);
  static const Color darkSurfaceLight = Color(0xFF1A2D45);
  static const Color darkOnBackground = Color(0xFFEAE6E0);
  static const Color darkOnSurface = Color(0xFFE8E4DF);
  static const Color darkOnSurfaceVariant = Color(0xFF8A9BB0);

  // Dark Glass
  static const Color darkGlassTint = Color(0x1AFFFFFF);
  static const Color darkGlassBorder = Color(0x26FFFFFF);
  static const Color darkGlassShadow = Color(0x33000000);

  // ── Gradient Mesh Backgrounds ──
  static const List<Color> lightMeshGradient = [
    Color(0xFF1E8C72),
    Color(0xFF1D3E5F),
    Color(0xFF2A5A8A),
    Color(0xFF14664F),
  ];

  static const List<Color> darkMeshGradient = [
    Color(0xFF0E3D2E),
    Color(0xFF0B1622),
    Color(0xFF162840),
    Color(0xFF0A2818),
  ];

  // ── Legacy (kept for backward compatibility during migration) ──
  static const Color background = Color(0xFFF7F4EB);
}
