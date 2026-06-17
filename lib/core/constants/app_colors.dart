import 'package:flutter/material.dart';

class AppColors {
  // Primary & Secondary Brand Colors
  static const Color primary = Color(0xFF1976D2);      // Sky Blue (Skripsi Theme)
  static const Color primaryLight = Color(0xFF63A4FF); // Light Blue
  static const Color primaryDark = Color(0xFF004BA0);  // Dark Blue
  static const Color accent = Color(0xFF03A9F4);       // Bright Blue/Cyan
  
  // Status Colors (sesuai status pengaduan)
  static const Color statusPending = Color(0xFF9E9E9E);      // Grey (Abu-abu)
  static const Color statusDiterima = Color(0xFF1976D2);     // Blue (Biru)
  static const Color statusTerverifikasi = Color(0xFFFBC02D); // Yellow (Kuning)
  static const Color statusDiproses = Color(0xFFF57C00);     // Orange (Oranye)
  static const Color statusSelesai = Color(0xFF388E3C);      // Green (Hijau)

  // Neutral Colors (Light Theme)
  static const Color background = Color(0xFFF5F7FA);   // Very light grey-blue background
  static const Color surface = Color(0xFFFFFFFF);      // White card backgrounds
  static const Color textPrimary = Color(0xFF212121);  // Dark Charcoal
  static const Color textSecondary = Color(0xFF757575);// Cool Grey
  static const Color border = Color(0xFFE0E0E0);       // Light Border Grey

  // Neutral Colors (Dark Theme)
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color borderDark = Color(0xFF2C2C2C);

  // Gradient definitions for premium look
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
