import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized text styles for the app
class AppTextStyles {
  // Headings
  static const heading1 = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w900,
    color: AppColors.textWhite,
    letterSpacing: 0.6,
    shadows: [
      Shadow(
        color: Color(0x44000000),
        offset: Offset(0, 2),
        blurRadius: 6,
      ),
    ],
  );

  static const heading2 = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w900,
    color: AppColors.textWhite,
    letterSpacing: 0.4,
    shadows: [
      Shadow(
        color: Color(0x33000000),
        offset: Offset(0, 1.5),
        blurRadius: 4,
      ),
    ],
  );

  static const heading3 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textWhite,
    letterSpacing: 0.3,
    shadows: [
      Shadow(
        color: Color(0x22000000),
        offset: Offset(0, 1),
        blurRadius: 3,
      ),
    ],
  );

  // White headings (for dark backgrounds)
  static const heading2White = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textWhite,
  );

  static const heading3White = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textWhite,
  );

  // Body text
  static const body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  // White body text (for dark backgrounds)
  static const body1White = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textWhite,
  );

  static const body2White = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textWhite,
  );

  // Secondary/muted text
  static const subtitle1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  static const subtitle2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  // White secondary text
  static const subtitle1White = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.inputHint,
  );

  static const subtitle2White = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.inputHint,
  );

  // Button text
  static const buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    // Use primary blue for text on white buttons so the label stands out
    color: AppColors.primary,
  );

  static const buttonTextWhite = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  // Caption/hint text
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textWhiteSecondary,
  );

  static const captionWhite = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.inputHint,
  );

  // Form field text
  static const formFieldText = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.2,
    shadows: [
      Shadow(
        color: Color(0x66000000),
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
    ],
  );

  static const formFieldHint = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Color(0xE6FFFFFF), // blanco con más opacidad
    letterSpacing: 0.2,
    shadows: [
      Shadow(
        color: Color(0x33000000),
        offset: Offset(0, 1),
        blurRadius: 1,
      ),
    ],
  );
}