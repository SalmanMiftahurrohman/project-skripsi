import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import 'admin_sidebar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Inisialisasi pendengar data secara real-time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComplaintProvider>().listenToAllComplaints();
      context.read<AuthProvider>().listenToAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final complaintProvider = Provider.of<ComplaintProvider>(context);

    // Hitung statistik
    final complaints = complaintProvider.complaints;
    final users = authProvider.users;

    final totalComplaints = complaints.length;
    final pendingComplaints = complaints.where((c) => c.status == 'Pending').length;
    final activeComplaints = complaints.where((c) => c.status == 'Diproses' || c.status == 'Diterima' || c.status == 'Terverifikasi').length;
    final resolvedComplaints = complaints.where((c) => c.status == 'Selesai').length;

    final totalCitizens = users.where((u) => u.role == 'masyarakat').length;
    final totalOfficers = users.where((u) => u.role == 'petugas').length;

    final bool isWide = MediaQuery.of(context).size.width > 900;

    Widget mainContent = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Banner
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang, Admin!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sistem Monitoring dan Penyelarasan Laporan Pengaduan Sampah GO-SAMPAH.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Statistics Header
          Text(
            'Ringkasan Statistik',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Grid Statistik (6 cards)
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isWide ? 3 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isWide ? 1.8 : 1.4,
            children: [
              _buildStatCard(
                context: context,
                title: 'Total Pengaduan',
                value: totalComplaints.toString(),
                icon: Icons.assignment_rounded,
                color: Colors.blue,
                bgColor: Colors.blue.withValues(alpha: 0.1),
              ),
              _buildStatCard(
                context: context,
                title: 'Menunggu',
                value: pendingComplaints.toString(),
                icon: Icons.hourglass_empty_rounded,
                color: Colors.grey,
                bgColor: Colors.grey.withValues(alpha: 0.1),
              ),
              _buildStatCard(
                context: context,
                title: 'Selesai',
                value: resolvedComplaints.toString(),
                icon: Icons.check_circle_outline_rounded,
                color: Colors.green,
                bgColor: Colors.green.withValues(alpha: 0.1),
              ),
              _buildStatCard(
                context: context,
                title: 'Diproses',
                value: activeComplaints.toString(),
                icon: Icons.loop_rounded,
                color: Colors.orange,
                bgColor: Colors.orange.withValues(alpha: 0.1),
              ),
              _buildStatCard(
                context: context,
                title: 'Masyarakat',
                value: totalCitizens.toString(),
                icon: Icons.people_alt_rounded,
                color: Colors.teal,
                bgColor: Colors.teal.withValues(alpha: 0.1),
              ),
              _buildStatCard(
                context: context,
                title: 'Petugas',
                value: totalOfficers.toString(),
                icon: Icons.engineering_rounded,
                color: Colors.indigo,
                bgColor: Colors.indigo.withValues(alpha: 0.1),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Complaints Table Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Pengaduan Terbaru',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.adminComplaints),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tabel Pengaduan
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border, width: 1),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: isWide ? MediaQuery.of(context).size.width - 320 : 600),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('No')),
                    DataColumn(label: Text('Judul')),
                    DataColumn(label: Text('Kategori')),
                    DataColumn(label: Text('Tanggal')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: List.generate(
                    complaints.take(5).length,
                    (index) {
                      final c = complaints[index];
                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(Text(c.title)),
                          DataCell(Text(c.category)),
                          DataCell(Text(
                            '${c.createdAt.day.toString().padLeft(2, '0')}/${c.createdAt.month.toString().padLeft(2, '0')}/${c.createdAt.year}',
                          )),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: c.status == 'Selesai'
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : c.status == 'Pending'
                                        ? Colors.grey.withValues(alpha: 0.1)
                                        : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                c.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: c.status == 'Selesai'
                                      ? Colors.green
                                      : c.status == 'Pending'
                                          ? Colors.grey
                                          : Colors.orange,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: isWide
          ? null
          : AppBar(
              title: const Text('Dashboard Admin'),
            ),
      drawer: isWide ? null : const Drawer(child: AdminSidebar(currentRoute: AppRoutes.adminDashboard)),
      body: Row(
        children: [
          if (isWide) const AdminSidebar(currentRoute: AppRoutes.adminDashboard),
          Expanded(child: mainContent),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
