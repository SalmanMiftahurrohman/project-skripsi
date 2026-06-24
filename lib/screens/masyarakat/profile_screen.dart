import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_overlay.dart';

/// Halaman [ProfileScreen] digunakan oleh pengguna untuk melihat dan mengedit data profil mereka.
/// 
/// Memungkinkan pembaruan data dasar (nama, nomor telepon, tanggal lahir, pekerjaan, alamat)
/// serta perubahan foto profil secara asinkron.
class ProfileScreen extends StatefulWidget {
  /// Menandakan apakah halaman profil ini ditampilkan sebagai tab di dalam menu navigasi utama.
  final bool isTab;

  /// Membuat instance baru dari [ProfileScreen].
  const ProfileScreen({super.key, this.isTab = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// State untuk [ProfileScreen] yang mengelola control form edit profil dan pemilihan file gambar lokal.
class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  File? _localImageFile;
  XFile? _pickedImageFile;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;
  late TextEditingController _occupationController;
  late TextEditingController _addressController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _birthDateController = TextEditingController();
    _occupationController = TextEditingController();
    _addressController = TextEditingController();
    _loadLocalImage();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _occupationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userModel = authProvider.userModel;
    if (userModel == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/profile_${userModel.uid}.png');
      if (await file.exists()) {
        setState(() {
          _localImageFile = file;
        });
      }
    } catch (e) {
      debugPrint('Error loading local image: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text('Ambil dari Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _pickedImageFile = pickedFile;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _startEditing(UserModel? userModel) {
    if (userModel == null) return;
    _nameController.text = userModel.name;
    _phoneController.text = userModel.phoneNumber;
    _birthDateController.text = userModel.birthDate;
    _occupationController.text = userModel.occupation;
    _addressController.text = userModel.address;
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _pickedImageFile = null;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userModel = authProvider.userModel;
    if (userModel == null) return;

    if (_pickedImageFile != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final String targetPath = '${directory.path}/profile_${userModel.uid}.png';
        final File localFile = File(targetPath);
        
        final savedFile = await File(_pickedImageFile!.path).copy(localFile.path);
        
        setState(() {
          _localImageFile = savedFile;
          _pickedImageFile = null;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan foto profil: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }

    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      birthDate: _birthDateController.text.trim(),
      occupation: _occupationController.text.trim(),
      address: _addressController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui! ✅'),
          backgroundColor: AppColors.statusSelesai,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Gagal memperbarui profil.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Akun'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authProvider.logout();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Logout berhasil.'),
              ],
            ),
            backgroundColor: Colors.blueGrey,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userModel = authProvider.userModel;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String initial = userModel != null && userModel.name.isNotEmpty
        ? userModel.name.substring(0, 1).toUpperCase()
        : 'U';

    final mainContent = LoadingOverlay(
      isLoading: authProvider.isLoading,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 8),

                // === Avatar dengan Dukungan Upload Foto Lokal ===
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _pickedImageFile != null || _localImageFile != null
                              ? null
                              : AppColors.primaryGradient,
                          color: _pickedImageFile != null || _localImageFile != null
                              ? Colors.grey[200]
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _pickedImageFile != null
                              ? Image.file(
                                  File(_pickedImageFile!.path),
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                )
                              : (_localImageFile != null
                                  ? Image.file(
                                      _localImageFile!,
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: Text(
                                        initial,
                                        style: const TextStyle(
                                          fontSize: 44,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )),
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Nama & Role
                Text(
                  userModel?.name ?? 'Nama Pengguna',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    userModel?.role.toUpperCase() ?? 'MASYARAKAT',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // === Form Fields ===
                _buildField(
                  context: context,
                  icon: Icons.person_outline_rounded,
                  label: 'Nama Lengkap',
                  controller: _nameController,
                  readOnly: !_isEditing,
                  isDark: isDark,
                  staticValue: userModel?.name ?? '-',
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Nama tidak boleh kosong'
                      : null,
                ),
                _buildField(
                  context: context,
                  icon: Icons.phone_android_rounded,
                  label: 'Nomor Telepon',
                  controller: _phoneController,
                  readOnly: !_isEditing,
                  isDark: isDark,
                  staticValue: userModel?.phoneNumber ?? '-',
                  keyboardType: TextInputType.phone,
                ),
                _buildField(
                  context: context,
                  icon: Icons.calendar_today_outlined,
                  label: 'Tanggal Lahir',
                  controller: _birthDateController,
                  readOnly: !_isEditing,
                  isDark: isDark,
                  staticValue: userModel?.birthDate.isNotEmpty == true
                      ? userModel!.birthDate
                      : '-',
                  hintText: 'Contoh: 01 Januari 2000',
                ),
                _buildField(
                  context: context,
                  icon: Icons.work_outline_rounded,
                  label: 'Pekerjaan',
                  controller: _occupationController,
                  readOnly: !_isEditing,
                  isDark: isDark,
                  staticValue: userModel?.occupation.isNotEmpty == true
                      ? userModel!.occupation
                      : '-',
                  hintText: 'Contoh: Mahasiswa',
                ),
                _buildField(
                  context: context,
                  icon: Icons.home_outlined,
                  label: 'Alamat',
                  controller: _addressController,
                  readOnly: !_isEditing,
                  isDark: isDark,
                  staticValue: userModel?.address.isNotEmpty == true
                      ? userModel!.address
                      : '-',
                  maxLines: 2,
                ),
                // Email (tidak bisa diedit)
                _buildField(
                  context: context,
                  icon: Icons.email_outlined,
                  label: 'Alamat Email',
                  controller: TextEditingController(text: userModel?.email ?? '-'),
                  readOnly: true,
                  isDark: isDark,
                  staticValue: userModel?.email ?? '-',
                  suffixText: 'Tidak dapat diubah',
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 24),

                // === Tombol Aksi ===
                if (!_isEditing) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startEditing(userModel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit Profil',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleLogout(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(AppStrings.logoutButton,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _cancelEditing,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Batal',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusSelesai,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Simpan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.isTab) {
      return mainContent;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profil' : 'Profil Saya'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _startEditing(userModel),
              tooltip: 'Edit Profil',
            ),
        ],
      ),
      body: mainContent,
    );
  }

  Widget _buildField({
    required BuildContext context,
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool readOnly,
    required bool isDark,
    required String staticValue,
    String? hintText,
    String? suffixText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: readOnly ? TextEditingController(text: staticValue) : controller,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          suffixText: suffixText,
          suffixStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 13,
          ),
          prefixIcon: Icon(
            icon,
            color: readOnly ? Colors.grey : AppColors.primary,
          ),
          filled: !readOnly,
          fillColor: readOnly
              ? null
              : (isDark
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : AppColors.primary.withValues(alpha: 0.03)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: readOnly ? Colors.grey[400]! : AppColors.primary,
              width: 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: readOnly
                  ? Colors.grey[400]!
                  : AppColors.primary.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
