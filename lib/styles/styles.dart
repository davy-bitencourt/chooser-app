import 'package:flutter/material.dart';

class AppColors {
  static const bgDeep     = Color(0xFF0A0A0F);
  static const bgSurface  = Color(0xFF12121C);

  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA0A0B8);

  static const primary = Color(0xFF5B52D9);
  static const danger       = Color(0xFFFF4757);
}

class AppStyles {

  static const textL1 = TextStyle(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );

  static const textB1 = TextStyle(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );

  static const textM1 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
  );
  
  static const textM2 = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 18,
  );

  static const textS1 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
  );

  static const textSS2 = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
  );
}