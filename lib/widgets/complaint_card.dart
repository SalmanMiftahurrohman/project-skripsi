import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../core/utils/date_formatter.dart';
import '../models/complaint_model.dart';
import 'app_image.dart';

/// Widget [ComplaintCard] menampilkan ringkasan informasi laporan pengaduan sampah
/// dalam bentuk kartu interaktif (card) yang dapat diklik.
class ComplaintCard extends StatelessWidget {
  /// Objek data model pengaduan sampah ([ComplaintModel]) yang ditampilkan pada kartu.
  final ComplaintModel complaint;

  /// Menandakan apakah tampilan kartu ini dikonsumsi oleh role Petugas.
  /// Memengaruhi navigasi detail ketika kartu diklik.
  final bool isOfficer;

  /// Aksi callback opsional ketika kartu diketuk (jika tidak null, menimpa aksi navigasi default).
  final VoidCallback? onTap;

  /// Membuat instance baru dari [ComplaintCard].
  const ComplaintCard({
    super.key,
    required this.complaint,
    this.isOfficer = false,
    this.onTap,
  });

  /// Mendapatkan warna representasi status visual berdasarkan status laporan [status].
  Color _getStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pending':
        return AppColors.statusPending;
      case 'diterima':
        return AppColors.statusDiterima;
      case 'terverifikasi':
        return AppColors.statusTerverifikasi;
      case 'diproses':
        return AppColors.statusDiproses;
      case 'selesai':
        return AppColors.statusSelesai;
      case 'ditolak':
        return Colors.redAccent;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timestamp = Timestamp.fromDate(complaint.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () {
          // Navigasi ke detail pengaduan sesuai role
          if (isOfficer) {
            context.push(AppRoutes.getOfficerComplaintDetailPath(complaint.id));
          } else {
            context.push(AppRoutes.getCitizenComplaintDetailPath(complaint.id));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gambar Bukti Sampah
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppImage(
                      imageUrl: complaint.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Detail Pengaduan
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Judul : ${complaint.title}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kategori Pengaduan : ${complaint.category}',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tanggal Pengaduan : ${DateFormatter.formatShortDate(timestamp)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status Pengaduan : ${complaint.status}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(complaint.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Tombol Lihat Detail di bagian bawah
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Lihat Detail',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
