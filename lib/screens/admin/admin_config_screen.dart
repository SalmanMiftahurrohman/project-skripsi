import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/config_provider.dart';
import '../../widgets/custom_text_field.dart';
import 'admin_sidebar.dart';

class AdminConfigScreen extends StatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  State<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends State<AdminConfigScreen> {
  final TextEditingController _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final configProvider = Provider.of<ConfigProvider>(context, listen: false);
      await configProvider.fetchOfficerCode();
      if (configProvider.officerCode != null) {
        _codeController.text = configProvider.officerCode!;
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final success = await configProvider.updateOfficerCode(_codeController.text.trim());

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode verifikasi petugas berhasil diperbarui!'),
          backgroundColor: AppColors.statusSelesai,
        ),
      );
    } else {
      final error = configProvider.errorMessage ?? 'Gagal memperbarui konfigurasi.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    final bool isWide = MediaQuery.of(context).size.width > 900;

    Widget mainContent = configProvider.isLoading && _codeController.text.isEmpty
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                if (isWide) ...[
                  Text(
                    'Konfigurasi Sistem',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kelola pengaturan sistem aplikasi GO-SAMPAH.',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Config Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.borderDark
                          : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Section title
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.vpn_key_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Kode Verifikasi Petugas',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Info Panel
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blueGrey.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.security_rounded, color: Colors.blueGrey),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Kode verifikasi digunakan oleh petugas kebersihan saat proses registrasi untuk memverifikasi keabsahan identitas mereka.',
                                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Input Code
                          CustomTextField(
                            controller: _codeController,
                            labelText: 'Kode Verifikasi Petugas',
                            hintText: 'Masukkan kode baru...',
                            prefixIcon: Icons.vpn_key_rounded,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Kode verifikasi tidak boleh kosong';
                              }
                              if (val.trim().length < 4) {
                                return 'Kode verifikasi minimal 4 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: configProvider.isLoading ? null : _saveConfig,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: configProvider.isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded, size: 18),
                              label: Text(
                                configProvider.isLoading ? 'Menyimpan...' : 'Simpan Perubahan',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
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
              title: const Text('Konfigurasi Sistem'),
            ),
      drawer: isWide ? null : const Drawer(child: AdminSidebar(currentRoute: AppRoutes.adminConfig)),
      body: Row(
        children: [
          if (isWide) const AdminSidebar(currentRoute: AppRoutes.adminConfig),
          Expanded(child: mainContent),
        ],
      ),
    );
  }
}
