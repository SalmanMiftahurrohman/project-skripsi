import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import 'admin_sidebar.dart';

class AdminOfficersScreen extends StatefulWidget {
  const AdminOfficersScreen({super.key});

  @override
  State<AdminOfficersScreen> createState() => _AdminOfficersScreenState();
}

class _AdminOfficersScreenState extends State<AdminOfficersScreen> {
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

    // Filter list user yang hanya role 'petugas' dan sesuai query pencarian
    final filteredOfficers = authProvider.users.where((user) {
      final matchesRole = user.role == 'petugas';
      final matchesSearch = user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesRole && matchesSearch;
    }).toList();

    Widget mainContent = Scaffold(
      appBar: AppBar(
        title: const Text('Data Petugas'),
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
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
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

          // Officers List
          Expanded(
            child: authProvider.isLoading && filteredOfficers.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                    ),
                  )
                : filteredOfficers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.engineering_outlined,
                              size: 64,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Petugas tidak ditemukan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filteredOfficers.length,
                        itemBuilder: (context, index) {
                          final officer = filteredOfficers[index];
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
                                  // Avatar bulat premium khusus petugas
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                                    child: const Icon(
                                      Icons.engineering_rounded,
                                      color: Colors.indigo,
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
                                          officer.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          officer.email,
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Terdaftar: ${DateFormatter.formatShortDate(
                                            Timestamp.fromDate(officer.createdAt),
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
      drawer: isWide ? null : const Drawer(child: AdminSidebar(currentRoute: AppRoutes.adminOfficers)),
      body: Row(
        children: [
          if (isWide) const AdminSidebar(currentRoute: AppRoutes.adminOfficers),
          Expanded(child: mainContent),
        ],
      ),
    );
  }
}
