import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import 'admin_sidebar.dart';

/// Halaman [AdminUsersScreen] menampilkan daftar seluruh pengguna terdaftar 
/// dengan peran Masyarakat (Citizen) beserta informasi profil dasar dan fitur pencarian nama.
class AdminUsersScreen extends StatefulWidget {
  /// Membuat instance baru dari [AdminUsersScreen].
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

/// State untuk [AdminUsersScreen] untuk memantau pencarian daftar masyarakat terdaftar.
class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().listenToAllUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isWide = MediaQuery.of(context).size.width > 900;

    // Filter list user yang hanya role 'masyarakat' dan sesuai query pencarian
    final filteredUsers = authProvider.users.where((user) {
      final matchesRole = user.role == 'masyarakat';
      final matchesSearch = user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesRole && matchesSearch;
    }).toList();

    Widget mainContent = Scaffold(
      appBar: AppBar(
        title: const Text('Data Masyarakat'),
        leading: isWide ? const SizedBox.shrink() : null,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama atau email...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
            ),
          ),

          // User List
          Expanded(
            child: authProvider.isLoading && filteredUsers.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 64,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Masyarakat tidak ditemukan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark ? AppColors.borderDark : AppColors.border,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Avatar bulat premium
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    child: const Icon(
                                      Icons.person,
                                      color: AppColors.primary,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Detail Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user.email,
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Terdaftar: ${DateFormatter.formatShortDate(
                                            Timestamp.fromDate(user.createdAt),
                                          )}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );

    return Scaffold(
      drawer: isWide ? null : const Drawer(child: AdminSidebar(currentRoute: AppRoutes.adminUsers)),
      body: Row(
        children: [
          if (isWide) const AdminSidebar(currentRoute: AppRoutes.adminUsers),
          Expanded(child: mainContent),
        ],
      ),
    );
  }
}
