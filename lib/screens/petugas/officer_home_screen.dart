import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/complaint_provider.dart';
import '../../widgets/complaint_card.dart';
import '../masyarakat/profile_screen.dart';

/// Halaman [OfficerHomeScreen] merupakan halaman utama (home) bagi pengguna Petugas (Officer).
/// 
/// Menyediakan navigasi bawah (bottom navigation bar) untuk beralih antara melihat daftar seluruh pengaduan sampah
/// yang masuk ke sistem, serta halaman Profil diri petugas.
class OfficerHomeScreen extends StatefulWidget {
  /// Membuat instance baru dari [OfficerHomeScreen].
  const OfficerHomeScreen({super.key});

  @override
  State<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

/// State untuk [OfficerHomeScreen] yang memantau indeks navigasi bawah dan pengunduhan daftar seluruh pengaduan.
class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAllComplaints();
  }

  void _loadAllComplaints() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ComplaintProvider>(context, listen: false).listenToAllComplaints();
    });
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter daftar pengaduan berdasarkan pilihan tab
    final filteredComplaints = complaintProvider.complaints.where((complaint) {
      final status = complaint.status.trim().toLowerCase();
      if (_currentIndex == 0) {
        return status == 'pending';
      } else if (_currentIndex == 1) {
        return status == 'diterima' || status == 'terverifikasi';
      } else if (_currentIndex == 2) {
        return status == 'diproses';
      } else if (_currentIndex == 3) {
        return status == 'selesai' || status == 'ditolak';
      }
      return false;
    }).toList();

    // Judul AppBar dinamis
    final String appBarTitle = _currentIndex == 0
        ? 'Pengaduan Diterima'
        : _currentIndex == 1
            ? 'Verifikasi Laporan'
            : _currentIndex == 2
                ? 'Sedang Diproses'
                : _currentIndex == 3
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
        child: _currentIndex == 4
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
                                    return ComplaintCard(
                                      complaint: complaint,
                                      isOfficer: true,
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
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
            icon: Icon(Icons.inbox_rounded),
            label: 'Diterima',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_rounded),
            label: 'Verifikasi',
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
    String message = 'Tidak ada laporan baru.';
    if (_currentIndex == 1) {
      message = 'Tidak ada laporan yang menunggu verifikasi.';
    } else if (_currentIndex == 2) {
      message = 'Tidak ada laporan yang sedang diproses.';
    } else if (_currentIndex == 3) {
      message = 'Belum ada laporan yang selesai ditangani.';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.task_alt_rounded,
          size: 72,
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        const SizedBox(height: 16),
        Text(
          'Tidak Ada Laporan',
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
        const SizedBox(height: 32),
      ],
    );
  }
}
