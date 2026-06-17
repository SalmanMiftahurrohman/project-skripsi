import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../widgets/complaint_card.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

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

    // Judul AppBar dinamis
    final String appBarTitle = _currentIndex == 0
        ? 'Riwayat Pengaduan'
        : _currentIndex == 1
            ? 'Sedang Diproses'
            : _currentIndex == 2
                ? 'Pengaduan Selesai'
                : 'Profil Saya';

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
                    Expanded(
                      child: complaintProvider.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            )
                          : filteredComplaints.isEmpty
                              ? _buildEmptyState(context, isDark)
                              : ListView.builder(
                                  itemCount: filteredComplaints.length,
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final complaint = filteredComplaints[index];
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
