import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2563EB); // Blue
  static const secondary = Color(0xFF10B981); // Green
  static const accent = Color(0xFFF59E0B); // Amber
  static const error = Color(0xFFEF4444); // Red
  static const success = Color(0xFF10B981); // Green
  
  static const background = Color(0xFFFAFAFA);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  
  // Tier colors
  static const bronze = Color(0xFFCD7F32);
  static const silver = Color(0xFFC0C0C0);
  static const gold = Color(0xFFFFD700);
  static const platinum = Color(0xFFE5E4E2);
}

class AppSizes {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
}

class AppStrings {
  static const appName = 'CareConnect';
  static const tagline = 'Blockchain-Powered Aid for Pediatric Cancer Warriors';
  
  // Tier names
  static const tierBronze = 'Bronze Champion';
  static const tierSilver = 'Silver Champion';
  static const tierGold = 'Gold Champion';
  static const tierPlatinum = 'Platinum Champion';
  
  // Tier thresholds
  static const tierBronzeMin = 1000;
  static const tierSilverMin = 5000;
  static const tierGoldMin = 20000;
  static const tierPlatinumMin = 50000;
}

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const landing = '/landing';
  static const donorHome = '/donor-home';
  static const adminDashboard = '/admin-dashboard';
  static const donate = '/donate';
  static const auctions = '/auctions';
  static const patients = '/patients';
  static const profile = '/profile';
}
