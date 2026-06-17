import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/feedback_provider.dart';
import '../../widgets/complaint_timeline.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_image.dart';
import '../../widgets/map_widget.dart';

class OfficerComplaintDetailScreen extends StatefulWidget {
  final String id;

  const OfficerComplaintDetailScreen({super.key, required this.id});

  @override
  State<OfficerComplaintDetailScreen> createState() => _OfficerComplaintDetailScreenState();
}

class _OfficerComplaintDetailScreenState extends State<OfficerComplaintDetailScreen> {
  late Future<ComplaintModel?> _fetchFuture;
  File? _evidenceFile;
  final ImagePicker _picker = ImagePicker();
  late FeedbackProvider _feedbackProvider;

  @override
  void initState() {
    super.initState();
    _loadComplaint();
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

  void _loadComplaint() {
    _fetchFuture = Provider.of<ComplaintProvider>(context, listen: false)
        .fetchComplaintById(widget.id);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FeedbackProvider>(context, listen: false)
          .fetchFeedbackForComplaint(widget.id);
    });
  }

  Future<void> _pickEvidenceImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (pickedFile != null) {
        setState(() {
          _evidenceFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil gambar bukti: $e')),
      );
    }
  }

  Future<void> _handleStatusUpdate(String newStatus, {String? rejectionReason}) async {
    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
    final success = await complaintProvider.updateStatus(
      widget.id,
      newStatus,
      rejectionReason: rejectionReason,
    );
    
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 'Ditolak' 
              ? 'Laporan berhasil ditolak.' 
              : 'Status laporan berhasil diperbarui menjadi "$newStatus".'),
          backgroundColor: AppColors.statusSelesai,
        ),
      );
      setState(() {
        _loadComplaint(); // Refresh data detail
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(complaintProvider.errorMessage ?? 'Gagal memperbarui status.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleResolve() async {
    if (_evidenceFile == null) return;

    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
    final success = await complaintProvider.resolveComplaint(widget.id, _evidenceFile!);
    
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan pengaduan berhasil diselesaikan! Bukti telah diunggah.'),
          backgroundColor: AppColors.statusSelesai,
        ),
      );
      setState(() {
        _evidenceFile = null;
        _loadComplaint(); // Refresh data
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(complaintProvider.errorMessage ?? 'Gagal menyelesaikan laporan.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showConfirmDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: title.contains('Tolak') ? Colors.redAccent : AppColors.primary,
            ),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      onConfirm();
    }
  }

  Future<void> _showRejectDialog({
    required Function(String reason) onConfirm,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RejectDialog(onConfirm: onConfirm),
    );
  }
  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengaduan (Petugas)'),
      ),
      body: LoadingOverlay(
        isLoading: complaintProvider.isLoading,
        child: FutureBuilder<ComplaintModel?>(
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
                    const Text('Gagal Memuat Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(snapshot.error?.toString() ?? 'Laporan tidak ditemukan.', style: const TextStyle(color: AppColors.textSecondary)),
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
                  // 1. Gambar Asli Laporan
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
                            label: 'Alasan Penolakan Laporan',
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

                        // 5. Bukti Penanganan Petugas (jika status Selesai)
                        if (complaint.status.trim() == 'Selesai' && complaint.evidenceImageUrl != null) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Bukti Penanganan Selesai',
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
                        const SizedBox(height: 32),

                        // Ulasan Masyarakat (jika status Selesai)
                        if (complaint.status.trim() == 'Selesai') ...[
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
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ulasan Masyarakat',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 12),
                                    Card(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: isDark ? AppColors.borderDark : AppColors.border,
                                          width: 1.5,
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
                                                  style: TextStyle(fontWeight: FontWeight.bold),
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
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              }
                              
                              return const SizedBox.shrink();
                            },
                          ),
                        ],

                        // 7. Panel Tindakan Petugas (Aksi Berjenjang)
                        _buildActionPanel(complaint, isDark),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionPanel(ComplaintModel complaint, bool isDark) {
    final status = complaint.status.trim();

    switch (status) {
      case 'Pending':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showRejectDialog(
                  onConfirm: (reason) => _handleStatusUpdate('Ditolak', rejectionReason: reason),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Tolak', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showConfirmDialog(
                  title: 'Terima Laporan',
                  message: 'Apakah Anda yakin ingin menerima laporan pengaduan sampah ini?',
                  onConfirm: () => _handleStatusUpdate('Diterima'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusSelesai,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Terima', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
        
      case 'Diterima':
        return ElevatedButton(
          onPressed: () => _showConfirmDialog(
            title: 'Verifikasi Laporan',
            message: 'Apakah Anda yakin ingin memverifikasi laporan pengaduan ini?',
            onConfirm: () => _handleStatusUpdate('Terverifikasi'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('Verifikasi Laporan Pengaduan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        );

      case 'Terverifikasi':
        return ElevatedButton(
          onPressed: () => _showConfirmDialog(
            title: 'Mulai Penanganan',
            message: 'Apakah Anda yakin ingin mulai memproses penanganan sampah di lokasi ini?',
            onConfirm: () => _handleStatusUpdate('Diproses'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.statusDiproses,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('Mulai Proses Penanganan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        );

      case 'Diproses':
        return Card(
          elevation: 0,
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Selesaikan Pekerjaan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ambil foto lokasi yang sudah bersih sebagai bukti penanganan selesai.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Area Gambar Bukti
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                              title: const Text('Ambil Foto dari Kamera'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickEvidenceImage(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library, color: AppColors.primary),
                              title: const Text('Pilih Foto dari Galeri'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickEvidenceImage(ImageSource.gallery);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : Colors.grey[400]!,
                        width: 1,
                      ),
                    ),
                    child: _evidenceFile != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_evidenceFile!, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                    onPressed: () => setState(() => _evidenceFile = null),
                                  ),
                                ),
                              )
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 48,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Ambil Foto Bukti Penanganan Selesai',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                ElevatedButton(
                  onPressed: _evidenceFile == null
                      ? null
                      : () => _showConfirmDialog(
                            title: 'Selesaikan Laporan',
                            message: 'Apakah Anda yakin penanganan sampah di lokasi ini sudah selesai dan ingin mengirim foto bukti?',
                            onConfirm: _handleResolve,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusSelesai,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Kirim Bukti & Selesaikan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );

      case 'Selesai':
      default:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.statusSelesai.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.statusSelesai.withValues(alpha: 0.2)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.statusSelesai),
              SizedBox(width: 12),
              Text(
                'Laporan ini telah diselesaikan.',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusSelesai),
              ),
            ],
          ),
        );
    }
  }
}

class CloudFirestoreTimestampHelper {
  static Timestamp? fromDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }
}

class _RejectDialog extends StatefulWidget {
  final Function(String) onConfirm;

  const _RejectDialog({required this.onConfirm});

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tolak Laporan'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Berikan alasan mengapa laporan pengaduan sampah ini ditolak:'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alasan Penolakan',
                hintText: 'Misal: Lokasi di luar jangkauan atau foto tidak jelas...',
                border: OutlineInputBorder(),
              ),
              validator: (val) => (val == null || val.trim().isEmpty)
                  ? 'Alasan penolakan tidak boleh kosong'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onConfirm(_controller.text.trim());
              Navigator.pop(context);
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
          child: const Text('Tolak Laporan'),
        ),
      ],
    );
  }
}
