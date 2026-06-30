import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/complaint_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../widgets/complaint_card.dart';
import 'profile_screen.dart';

/// Halaman [HomeScreen] merupakan halaman utama (home) bagi pengguna Masyarakat (Citizen).
/// 
/// Menyediakan navigasi bawah (bottom navigation bar) untuk beralih antara melihat daftar riwayat laporan
/// pengaduan sampah yang dikirim sendiri oleh pengguna, serta halaman Profil diri.
class HomeScreen extends StatefulWidget {
  /// Membuat instance baru dari [HomeScreen].
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// State untuk [HomeScreen] yang mengatur indeks navigasi bawah dan pengunduhan riwayat laporan sampah milik pengguna.
class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  void _loadComplaints() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;
      if (userId != null) {
        Provider.of<ComplaintProvider>(context, listen: false)
            .listenToUserComplaints(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter aduan berdasarkan tab indeks saat ini
    final filteredComplaints = complaintProvider.complaints.where((complaint) {
      final status = complaint.status.trim().toLowerCase();
      if (_currentIndex == 0) {
        return status == 'pending' || status == 'diterima' || status == 'terverifikasi';
      } else if (_currentIndex == 1) {
        return status == 'diproses';
      } else if (_currentIndex == 2) {
        return status == 'selesai' || status == 'ditolak';
      }
      return false;
    }).toList();

    // Petakan laporan pembuatan offline baru agar bisa ditampilkan di riwayat (tab 0)
    final List<ComplaintModel> mappedPendingComplaints = _currentIndex == 0
        ? complaintProvider.pendingComplaints.map((item) {
            return ComplaintModel(
              id: item.id,
              userId: item.userId,
              title: item.title,
              description: item.description,
              imageUrl: item.localImagePath,
              latitude: item.latitude,
              longitude: item.longitude,
              address: item.address,
              category: item.category,
              status: 'Menunggu Sinkronisasi',
              createdAt: item.createdAt,
            );
          }).toList()
        : [];

    final List<ComplaintModel> allComplaintsToShow = [
      ...mappedPendingComplaints,
      ...filteredComplaints,
    ];

    // Judul AppBar dinamis
    final String appBarTitle = _currentIndex == 0
        ? 'Riwayat Pengaduan'
        : _currentIndex == 1
            ? 'Sedang Diproses'
            : _currentIndex == 2
                ? 'Pengaduan Selesai'
                : 'Profil Saya';

    final pendingComplaints = complaintProvider.pendingComplaints;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: _currentIndex == 3
            ? const ProfileScreen(isTab: true)
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    if (pendingComplaints.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sync_problem_rounded, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ada ${pendingComplaints.length} Laporan Tertunda',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Belum terunggah karena offline.',
                                    style: TextStyle(fontSize: 12, color: Colors.orange),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await complaintProvider.syncOfflineQueue();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Sinkronkan', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Expanded(
                      child: complaintProvider.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            )
                          : allComplaintsToShow.isEmpty
                              ? _buildEmptyState(context, isDark)
                              : ListView.builder(
                                  itemCount: allComplaintsToShow.length,
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final complaint = allComplaintsToShow[index];
                                    return ComplaintCard(complaint: complaint);
                                  },
                                ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: _currentIndex == 3
          ? null
          : FloatingActionButton(
              onPressed: () => context.push(AppRoutes.citizenCreateComplaint),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              tooltip: 'Laporkan Sampah',
              child: const Icon(Icons.add, size: 28),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sync_rounded),
            label: 'Diproses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline_rounded),
            label: 'Selesai',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    String message = 'Belum ada pengaduan baru.';
    if (_currentIndex == 1) {
      message = 'Tidak ada pengaduan yang sedang diproses.';
    } else if (_currentIndex == 2) {
      message = 'Belum ada pengaduan yang selesai ditangani.';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.delete_outline_outlined,
          size: 80,
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        const SizedBox(height: 16),
        Text(
          'Belum Ada Laporan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
