import 'package:flutter/material.dart';

/// Kelas [AppColors] menyimpan semua konstanta warna yang digunakan
/// dalam sistem desain aplikasi GO - SAMPAH, termasuk tema terang (light) dan gelap (dark).
class AppColors {
  /// Warna utama (primary brand color) bertema Biru Langit (Sky Blue).
  static const Color primary = Color(0xFF1976D2);      // Sky Blue (Skripsi Theme)

  /// Warna utama versi terang untuk aksen atau background card/button yang menonjol.
  static const Color primaryLight = Color(0xFF63A4FF); // Light Blue

  /// Warna utama versi gelap untuk aksen header atau teks bernada biru tua.
  static const Color primaryDark = Color(0xFF004BA0);  // Dark Blue

  /// Warna aksen (secondary brand color) bertema Biru Terang/Cyan.
  static const Color accent = Color(0xFF03A9F4);       // Bright Blue/Cyan
  
  /// Warna status 'Pending' (Menunggu konfirmasi petugas). Direpresentasikan dengan warna Abu-abu.
  static const Color statusPending = Color(0xFF9E9E9E);      // Grey (Abu-abu)

  /// Warna status 'Diterima' (Laporan diterima sistem). Direpresentasikan dengan warna Biru.
  static const Color statusDiterima = Color(0xFF1976D2);     // Blue (Biru)

  /// Warna status 'Terverifikasi' (Laporan terverifikasi valid). Direpresentasikan dengan warna Kuning.
  static const Color statusTerverifikasi = Color(0xFFFBC02D); // Yellow (Kuning)

  /// Warna status 'Diproses' (Petugas sedang menangani sampah). Direpresentasikan dengan warna Oranye.
  static const Color statusDiproses = Color(0xFFF57C00);     // Orange (Oranye)

  /// Warna status 'Selesai' (Penumpukan sampah teratasi). Direpresentasikan dengan warna Hijau.
  static const Color statusSelesai = Color(0xFF388E3C);      // Green (Hijau)

  /// Warna latar belakang (background) untuk tema terang.
  static const Color background = Color(0xFFF5F7FA);   // Very light grey-blue background

  /// Warna permukaan (surface) seperti kartu/card, kontainer, dan dialog untuk tema terang.
  static const Color surface = Color(0xFFFFFFFF);      // White card backgrounds

  /// Warna teks utama (primary text) untuk keterbacaan tinggi di tema terang.
  static const Color textPrimary = Color(0xFF212121);  // Dark Charcoal

  /// Warna teks sekunder (secondary text) untuk teks pelengkap atau label di tema terang.
  static const Color textSecondary = Color(0xFF757575);// Cool Grey

  /// Warna garis tepi (border) atau pemisah (divider) untuk tema terang.
  static const Color border = Color(0xFFE0E0E0);       // Light Border Grey

  /// Warna latar belakang (background) untuk tema gelap.
  static const Color backgroundDark = Color(0xFF121212);

  /// Warna permukaan (surface) untuk tema gelap.
  static const Color surfaceDark = Color(0xFF1E1E1E);

  /// Warna teks utama (primary text) untuk tema gelap.
  static const Color textPrimaryDark = Color(0xFFF5F5F5);

  /// Warna teks sekunder (secondary text) untuk tema gelap.
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  /// Warna garis tepi (border) untuk tema gelap.
  static const Color borderDark = Color(0xFF2C2C2C);

  /// Gradasi warna utama untuk memberikan tampilan premium pada elemen UI (seperti tombol/header).
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Gradasi warna aksen untuk memberikan variasi visual premium pada elemen UI tertentu.
  static const Gradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
