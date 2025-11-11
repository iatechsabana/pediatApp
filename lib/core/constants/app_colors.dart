import 'package:flutter/material.dart';

/// Centralized color palette for the pediatric app
class AppColors {
  // Primary brand colors (solid metallic blue)
  // Deeper, more saturated metallic blue for stronger contrast
  static const primary = Color(0xFF153A54); // solid metallic blue
  static const primaryLight = Color(0xFFD9EEF9);

  // Background & Surfaces
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const scaffoldBackground = Color(0xFFFAFAFA);

  // Text colors
  static const text = Color(0xFF212121);
  static const textSecondary = Color(0xFF5F6A70);
  static const textHint = Color(0xFF9EA6AB);
  static const textWhite = Color(0xFFFFFFFF);
  static const textWhiteSecondary = Color(0xFFF5F8FA);
  static const textBlack54 = Color(0xFF000000);

  // Control labels / small UI text on primary backgrounds: use near-white for strong contrast
  static const controlText = Color(0xFFF5F8FA);

  // Input fields (forms)
  // Input fills and hints tuned for visibility over blue backgrounds
  static const inputFill = Color(0x14FFFFFF); // semi-transparent white
  static const inputFillDark = Color(0x0A000000);
  static const inputHint = Color(0xB3FFFFFF); // white hint with opacity
  static const inputBorder = Color(0x33FFFFFF);
  static const inputIcon = Color(0xFFFFFFFF);

  // Semantic colors
  static const error = Color(0xFFD32F2F);
  static const success = Color(0xFF388E3C);
  static const warning = Color(0xFFF57C00);
  static const info = Color(0xFF1976D2);

  // Overlay & shadows
  static const overlay = Color(0x00000000);
  static const overlayLight = Color(0x0A000000); // 4% opacity black
  static const overlayShadow = Color(0x0A000000); // for shadows

  // Icon colors
  static const iconPrimary = Color(0xFFFFFFFF);
  static const iconSecondary = Color(0xFF5F6A70);
  static const iconLight = Color(0xFFFFFFFF);

  // Gradient colors
  static const Color gradientStart = Color(0xFFD9EEF9);
  static const Color gradientEnd = Color(0xFF153A54);

  // Badge/Tag colors
  static const badgeBackground = Color(0xFF153A54);
}