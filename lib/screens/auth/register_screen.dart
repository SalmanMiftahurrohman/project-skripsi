import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';

/// Halaman [RegisterScreen] berfungsi sebagai layar perantara pemilihan tipe akun (role).
/// 
/// Memungkinkan calon pendaftar memilih mendaftar sebagai 'Masyarakat' (Citizen) 
/// atau 'Petugas Kebersihan' (Officer).
class RegisterScreen extends StatelessWidget {
  /// Membuat instance baru dari [RegisterScreen].
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppBar(
        title: const Text('Pilih Tipe Akun'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.primary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Daftar Akun Baru',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih tipe akun Anda untuk melanjutkan proses registrasi',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 48),

              // Card Pilihan 1: Masyarakat
              _buildChoiceCard(
                context: context,
                title: 'Masyarakat',
                description: 'Laporkan penumpukan sampah di lingkungan Anda dan pantau status penanganannya secara real-time.',
                icon: Icons.people_alt_rounded,
                onTap: () => context.push(AppRoutes.registerCitizen),
              ),
              const SizedBox(height: 24),

              // Card Pilihan 2: Petugas
              _buildChoiceCard(
                context: context,
                title: 'Petugas Kebersihan',
                description: 'Verifikasi pengaduan, perbarui status penanganan, dan unggah foto bukti sampah yang telah dibersihkan.',
                icon: Icons.cleaning_services_rounded,
                onTap: () => context.push(AppRoutes.registerOfficer),
              ),
              
              const Spacer(),
              
              // Back to Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sudah memiliki akun?'),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Masuk'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Membangun pilihan kartu (choice card) untuk membagi pendaftaran role.
  /// 
  /// Menerima parameter [title] (nama role), [description] (penjelasan hak akses), 
  /// [icon] pendukung, dan callback [onTap] untuk navigasi.
  Widget _buildChoiceCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
