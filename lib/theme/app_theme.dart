import 'package:flutter/material.dart';

/// Shared design tokens mirroring the original web app's dark neutral / amber palette.
class AppColors {
  AppColors._();

  static const neutral950 = Color(0xFF0A0A0A);
  static const neutral900 = Color(0xFF171717);
  static const neutral850 = Color(0xFF1F1F1F);
  static const neutral800 = Color(0xFF262626);
  static const neutral700 = Color(0xFF404040);
  static const neutral400 = Color(0xFFA3A3A3);
  static const neutral300 = Color(0xFFD4D4D4);
  static const neutral100 = Color(0xFFF5F5F5);

  static const amber500 = Color(0xFFF59E0B);
  static const amber600 = Color(0xFFD97706);

  static const red500 = Color(0xFFEF4444);
  static const orange500 = Color(0xFFF97316);
  static const green500 = Color(0xFF22C55E);
  static const blue500 = Color(0xFF3B82F6);
  static const yellow500 = Color(0xFFEAB308);

  static Color severityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return red500;
      case 'High':
        return orange500;
      case 'Medium':
        return yellow500;
      default:
        return blue500;
    }
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'Active':
      case 'Approved':
      case 'Completed':
      case 'Verified':
      case 'Resolved':
        return green500;
      case 'Flagged':
      case 'Critical':
      case 'Rejected':
      case 'Tampered':
        return red500;
      case 'Overdue':
      case 'Under Investigation':
      case 'In Investigation':
      case 'Pending Approval':
      case 'Pending':
        return orange500;
      case 'Requested':
      case 'In Garage':
        return blue500;
      case 'Parked':
      case 'Offline':
      case 'Grounded':
      case 'Suspended':
        return neutral400;
      default:
        return amber500;
    }
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.neutral950,
      primaryColor: AppColors.amber500,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.amber500,
        secondary: AppColors.amber500,
        surface: AppColors.neutral900,
        error: AppColors.red500,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.neutral900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: const CardTheme(
        color: AppColors.neutral900,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: AppColors.neutral800),
        ),
      ),
      dividerColor: AppColors.neutral800,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.neutral100,
        displayColor: AppColors.neutral100,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber500,
          foregroundColor: AppColors.neutral950,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.neutral100,
          side: const BorderSide(color: AppColors.neutral700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral950,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neutral800),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neutral800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.amber500),
        ),
        labelStyle: const TextStyle(color: AppColors.neutral400, fontSize: 12),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.neutral850,
        labelStyle: const TextStyle(color: AppColors.neutral100, fontSize: 11),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.neutral850,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
