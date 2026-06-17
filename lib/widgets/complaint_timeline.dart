import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/date_formatter.dart';
import '../models/complaint_model.dart';

class ComplaintTimeline extends StatelessWidget {
  final ComplaintModel complaint;

  const ComplaintTimeline({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    // Tentukan tahap keaktifan status
    final currentStatus = complaint.status.trim();
    final isRejected = currentStatus == 'Ditolak';
    
    // Status hierarchy
    final int activeStep;
    if (currentStatus == 'Diterima') {
      activeStep = 1;
    } else if (currentStatus == 'Terverifikasi') {
      activeStep = 2;
    } else if (currentStatus == 'Diproses') {
      activeStep = 3;
    } else if (currentStatus == 'Selesai') {
      activeStep = 4;
    } else {
      activeStep = 0; // 'Pending' atau 'Ditolak'
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Alur Penanganan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        
        if (isRejected) ...[
          // Step 1: Pending (Laporan Dikirim)
          _buildTimelineStep(
            context: context,
            title: 'Laporan Dikirim',
            description: 'Laporan Anda telah berhasil masuk ke sistem kami.',
            timestamp: CloudFirestoreTimestampHelper.fromDateTime(complaint.createdAt),
            isActive: true,
            isCompleted: true,
            isLast: false,
            isDark: isDark,
          ),
          // Step 2: Ditolak
          _buildTimelineStep(
            context: context,
            title: 'Laporan Ditolak',
            description: 'Laporan ditolak oleh petugas. Alasan: ${complaint.rejectionReason ?? "Tidak ditentukan"}',
            timestamp: complaint.resolvedAt != null ? CloudFirestoreTimestampHelper.fromDateTime(complaint.resolvedAt!) : null,
            isActive: true,
            isCompleted: true,
            isLast: true,
            isDark: isDark,
            customColor: Colors.redAccent,
            isRejectedStep: true,
          ),
        ] else ...[
          // Step 1: Pending
          _buildTimelineStep(
            context: context,
            title: 'Laporan Dikirim',
            description: 'Laporan Anda telah berhasil masuk ke sistem kami.',
            timestamp: CloudFirestoreTimestampHelper.fromDateTime(complaint.createdAt),
            isActive: activeStep >= 0,
            isCompleted: activeStep > 0,
            isLast: false,
            isDark: isDark,
          ),
          
          // Step 2: Diterima
          _buildTimelineStep(
            context: context,
            title: 'Laporan Diterima',
            description: 'Laporan telah diterima oleh petugas kebersihan daerah.',
            timestamp: activeStep >= 1 ? CloudFirestoreTimestampHelper.fromDateTime(complaint.createdAt) : null,
            isActive: activeStep >= 1,
            isCompleted: activeStep > 1,
            isLast: false,
            isDark: isDark,
          ),
          
          // Step 3: Terverifikasi
          _buildTimelineStep(
            context: context,
            title: 'Laporan Terverifikasi',
            description: 'Lokasi dan laporan sampah telah divalidasi kebenarannya.',
            timestamp: activeStep >= 2 ? CloudFirestoreTimestampHelper.fromDateTime(complaint.createdAt) : null,
            isActive: activeStep >= 2,
            isCompleted: activeStep > 2,
            isLast: false,
            isDark: isDark,
          ),
          
          // Step 4: Diproses
          _buildTimelineStep(
            context: context,
            title: 'Sedang Diproses',
            description: 'Petugas kebersihan sedang membersihkan sampah di lokasi.',
            timestamp: complaint.processedAt != null ? CloudFirestoreTimestampHelper.fromDateTime(complaint.processedAt!) : null,
            isActive: activeStep >= 3,
            isCompleted: activeStep > 3,
            isLast: false,
            isDark: isDark,
          ),
          
          // Step 5: Selesai
          _buildTimelineStep(
            context: context,
            title: 'Laporan Selesai',
            description: 'Sampah telah dibersihkan sepenuhnya. Terima kasih atas laporan Anda!',
            timestamp: complaint.resolvedAt != null ? CloudFirestoreTimestampHelper.fromDateTime(complaint.resolvedAt!) : null,
            isActive: activeStep >= 4,
            isCompleted: activeStep >= 4,
            isLast: true,
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildTimelineStep({
    required BuildContext context,
    required String title,
    required String description,
    required Timestamp? timestamp,
    required bool isActive,
    required bool isCompleted,
    required bool isLast,
    required bool isDark,
    Color? customColor,
    bool isRejectedStep = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kolom Kiri: Dot & Garis Penghubung
        Column(
          children: [
            // Dot lingkaran
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: customColor ??
                    (isCompleted
                        ? AppColors.statusSelesai
                        : isActive
                            ? AppColors.primary
                            : isDark
                                ? Colors.grey[800]
                                : Colors.grey[300]),
                border: Border.all(
                  color: isCompleted
                      ? Colors.transparent
                      : isActive
                          ? Colors.white
                          : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? Icon(
                        isRejectedStep ? Icons.close : Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : isActive
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          )
                        : const SizedBox(),
              ),
            ),
            
            // Garis Penghubung
            if (!isLast)
              Container(
                width: 3,
                height: 50,
                color: customColor ??
                    (isCompleted
                        ? AppColors.statusSelesai
                        : isDark
                            ? Colors.grey[800]
                            : Colors.grey[300]),
              ),
          ],
        ),
        const SizedBox(width: 16),
        
        // Kolom Kanan: Teks Info Detail Tahap
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? isDark
                              ? Colors.white
                              : Colors.black87
                          : isDark
                              ? Colors.grey[600]
                              : Colors.grey[400],
                    ),
                  ),
                  if (timestamp != null)
                    Text(
                      DateFormatter.formatShortDate(timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: isActive
                      ? isDark
                          ? Colors.grey[400]
                          : Colors.grey[700]
                      : isDark
                          ? Colors.grey[700]
                          : Colors.grey[400],
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class CloudFirestoreTimestampHelper {
  static Timestamp? fromDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }
}
