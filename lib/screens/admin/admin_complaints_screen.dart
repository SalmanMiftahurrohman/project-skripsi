import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/feedback_provider.dart';
import '../../widgets/complaint_card.dart';
import '../../widgets/complaint_timeline.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_image.dart';
import 'admin_sidebar.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _statuses = ['Semua', 'Pending', 'Diterima', 'Terverifikasi', 'Diproses', 'Selesai', 'Ditolak'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    // Jalankan listener data real-time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComplaintProvider>().listenToAllComplaints();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDetailBottomSheet(ComplaintModel complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AdminComplaintDetailBottomSheet(complaint: complaint),
    );
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isWide = MediaQuery.of(context).size.width > 900;

    Widget mainContent = Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Laporan Sampah'),
        leading: isWide ? const SizedBox.shrink() : null,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _statuses.map((status) => Tab(text: status)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses.map((status) {
          final filteredList = status == 'Semua'
              ? complaintProvider.complaints
              : complaintProvider.complaints.where((c) => c.status.trim() == status).toList();

          if (complaintProvider.isLoading && filteredList.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (filteredList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_late_outlined,
                    size: 64,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada laporan status "$status"',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final complaint = filteredList[index];
              return ComplaintCard(
                complaint: complaint,
                onTap: () => _showDetailBottomSheet(complaint),
              );
            },
          );
        }).toList(),
      ),
    );

    return Scaffold(
      drawer: isWide ? null : const Drawer(child: AdminSidebar(currentRoute: AppRoutes.adminComplaints)),
      body: Row(
        children: [
          if (isWide) const AdminSidebar(currentRoute: AppRoutes.adminComplaints),
          Expanded(child: mainContent),
        ],
      ),
    );
  }
}

class _AdminComplaintDetailBottomSheet extends StatefulWidget {
  final ComplaintModel complaint;

  const _AdminComplaintDetailBottomSheet({required this.complaint});

  @override
  State<_AdminComplaintDetailBottomSheet> createState() => _AdminComplaintDetailBottomSheetState();
}

class _AdminComplaintDetailBottomSheetState extends State<_AdminComplaintDetailBottomSheet> {
  late FeedbackProvider _feedbackProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedbackProvider>().fetchFeedbackForComplaint(widget.complaint.id);
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

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header Halaman
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Detail Laporan Admin',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

          // Body Detail
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gambar Utama Sampah
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AppImage(
                      imageUrl: complaint.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Judul & Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          complaint.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      StatusBadge(status: complaint.status),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Tanggal Laporan
                  Text(
                    'Dilaporkan pada: ${DateFormatter.formatTimestamp(
                      Timestamp.fromDate(complaint.createdAt),
                    )}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (complaint.status.trim() == 'Ditolak' && complaint.rejectionReason != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Alasan Penolakan Petugas:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              complaint.rejectionReason!,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Deskripsi Laporan
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deskripsi:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            complaint.description,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Alamat & Koordinat Lokasi
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lokasi Kejadian:',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  complaint.address,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Koordinat: ${complaint.latitude}, ${complaint.longitude}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bukti Penanganan Selesai (jika ada)
                  if (complaint.status.trim() == 'Selesai' && complaint.evidenceImageUrl != null) ...[
                    const Text(
                      'Bukti Penanganan Selesai',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AppImage(
                        imageUrl: complaint.evidenceImageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Timeline Tracker
                  const Text(
                    'Timeline Progress',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ComplaintTimeline(complaint: complaint),
                  const SizedBox(height: 24),

                  // Ulasan Masyarakat (jika status Selesai)
                  if (complaint.status.trim() == 'Selesai') ...[
                    Consumer<FeedbackProvider>(
                      builder: (context, feedbackProvider, child) {
                        if (feedbackProvider.isLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final feedback = feedbackProvider.currentFeedback;
                        if (feedback != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ulasan Dari Pelapor',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isDark ? AppColors.borderDark : AppColors.border,
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
                                          const Text(
                                            'Rating Layanan',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Row(
                                            children: List.generate(5, (index) {
                                              return Icon(
                                                index < feedback.rating
                                                    ? Icons.star_rounded
                                                    : Icons.star_outline_rounded,
                                                color: Colors.amber,
                                                size: 18,
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
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
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
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
                              ),
                            ],
                          );
                        }

                        return const Card(
                          elevation: 0,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rate_review_outlined, color: AppColors.textSecondary, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Pelapor belum memberikan ulasan penanganan.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
