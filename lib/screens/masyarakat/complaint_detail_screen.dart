import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/complaint_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/feedback_provider.dart';
import '../../widgets/complaint_timeline.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/feedback_dialog.dart';
import '../../widgets/app_image.dart';
import '../../widgets/map_widget.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final String id;

  const ComplaintDetailScreen({super.key, required this.id});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  late Future<ComplaintModel?> _fetchFuture;
  late FeedbackProvider _feedbackProvider;

  @override
  void initState() {
    super.initState();
    _fetchFuture = Provider.of<ComplaintProvider>(context, listen: false)
        .fetchComplaintById(widget.id);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FeedbackProvider>(context, listen: false)
          .fetchFeedbackForComplaint(widget.id);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _feedbackProvider = Provider.of<FeedbackProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _feedbackProvider.clearFeedback();
    super.dispose();
  }

  Future<void> _openMap(double latitude, double longitude) async {
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");
    try {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch Google Maps: $e');
    }
  }

  Widget _buildDetailBox({required String label, required Widget content}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey[300]!,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengaduan'),
      ),
      body: FutureBuilder<ComplaintModel?>(
        future: _fetchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'Gagal Memuat Laporan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error?.toString() ?? 'Laporan tidak ditemukan.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          final complaint = snapshot.data!;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Gambar Utama Laporan Sampah
                AppImage(
                  imageUrl: complaint.imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDetailBox(
                        label: 'Status Pengaduan',
                        content: Row(
                          children: [
                            StatusBadge(status: complaint.status),
                          ],
                        ),
                      ),
                      if (complaint.status.trim() == 'Ditolak' && complaint.rejectionReason != null) ...[
                        _buildDetailBox(
                          label: 'Alasan Penolakan Petugas',
                          content: Text(
                            complaint.rejectionReason!,
                            style: const TextStyle(fontSize: 15, color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      _buildDetailBox(
                        label: 'Judul Pengaduan',
                        content: Text(
                          complaint.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildDetailBox(
                        label: 'Tanggal Pengaduan',
                        content: Text(
                          DateFormatter.formatTimestamp(
                            CloudFirestoreTimestampHelper.fromDateTime(complaint.createdAt),
                          ),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      _buildDetailBox(
                        label: 'Lokasi Pengaduan',
                        content: Text(
                          complaint.address,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ),
                      _buildDetailBox(
                        label: 'Detail Lokasi',
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Koordinat: ${complaint.latitude}, ${complaint.longitude}',
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 12),
                            MapWidget(
                              initialLatitude: complaint.latitude,
                              initialLongitude: complaint.longitude,
                              isReadOnly: true,
                              showGeofence: false,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _openMap(complaint.latitude, complaint.longitude),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('Buka Google Maps Eksternal'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildDetailBox(
                        label: 'Kategori Pengaduan',
                        content: Text(
                          complaint.category,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      _buildDetailBox(
                        label: 'Keterangan Pengaduan',
                        content: Text(
                          complaint.description,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ),

                      // 5. Bukti Penanganan Petugas (jika ada)
                      if (complaint.status.trim() == 'Selesai' && complaint.evidenceImageUrl != null) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Bukti Penanganan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AppImage(
                            imageUrl: complaint.evidenceImageUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 6. Timeline Tracker
                      ComplaintTimeline(complaint: complaint),
                      const SizedBox(height: 24),

                      // 7. Feedback Section (jika status Selesai)
                      if (complaint.status.trim() == 'Selesai') ...[
                        const Divider(height: 32),
                        Consumer<FeedbackProvider>(
                          builder: (context, feedbackProvider, child) {
                            if (feedbackProvider.isLoading) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                ),
                              );
                            }

                            final feedback = feedbackProvider.currentFeedback;
                            if (feedback != null) {
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isDark ? AppColors.borderDark : AppColors.border,
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Ulasan Anda',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                            ),
                                          ),
                                          Row(
                                            children: List.generate(5, (index) {
                                              return Icon(
                                                index < feedback.rating
                                                    ? Icons.star_rounded
                                                    : Icons.star_outline_rounded,
                                                color: Colors.amber,
                                                size: 20,
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (feedback.comment.isNotEmpty) ...[
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isDark 
                                                ? AppColors.backgroundDark 
                                                : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '"${feedback.comment}"',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                              color: isDark 
                                                  ? AppColors.textPrimaryDark 
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      Text(
                                        'Dikirim pada: ${DateFormatter.formatTimestamp(
                                          Timestamp.fromDate(feedback.createdAt),
                                        )}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                  final userId = authProvider.userModel?.uid ?? '';
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => FeedbackDialog(
                                      complaintId: complaint.id,
                                      userId: userId,
                                    ),
                                  ).then((success) {
                                    if (success == true) {
                                      feedbackProvider.fetchFeedbackForComplaint(complaint.id);
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.rate_review_rounded),
                                label: const Text(
                                  'Beri Ulasan Penanganan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
