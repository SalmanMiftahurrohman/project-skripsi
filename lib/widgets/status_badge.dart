import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Widget [StatusBadge] menampilkan label (badge) berwarna yang melambangkan 
/// status penanganan dari laporan pengaduan sampah tertentu.
class StatusBadge extends StatelessWidget {
  /// String nama status laporan pengaduan (contoh: 'Pending', 'Diterima', 'Selesai', dll).
  final String status;

  /// Membuat instance baru dari [StatusBadge].
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color textColor = Colors.white;

    switch (status.trim()) {
      case 'Diterima':
        badgeColor = AppColors.statusDiterima;
        break;
      case 'Terverifikasi':
        badgeColor = AppColors.statusTerverifikasi;
        textColor = Colors.black87; // Warna teks gelap agar terbaca pada latar kuning
        break;
      case 'Diproses':
        badgeColor = AppColors.statusDiproses;
        break;
      case 'Selesai':
        badgeColor = AppColors.statusSelesai;
        break;
      case 'Ditolak':
        badgeColor = Colors.redAccent;
        break;
      case 'Pending':
      default:
        badgeColor = AppColors.statusPending;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
