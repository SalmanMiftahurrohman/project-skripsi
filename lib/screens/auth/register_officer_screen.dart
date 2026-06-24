import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

/// Halaman [RegisterOfficerScreen] menyediakan form registrasi pendaftaran akun baru
/// khusus bagi Petugas lapangan. Pendaftaran memerlukan kode verifikasi khusus petugas.
class RegisterOfficerScreen extends StatefulWidget {
  /// Membuat instance baru dari [RegisterOfficerScreen].
  const RegisterOfficerScreen({super.key});

  @override
  State<RegisterOfficerScreen> createState() => _RegisterOfficerScreenState();
}

/// State dari [RegisterOfficerScreen] untuk mengontrol input form pendaftaran petugas dan penyerahan data.
class _RegisterOfficerScreenState extends State<RegisterOfficerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Menangani proses pendaftaran akun petugas lapangan.
  /// 
  /// Memvalidasi form input, memanggil [AuthProvider.registerOfficer], dan mengarahkan petugas
  /// ke halaman beranda petugas lapangan setelah pendaftaran diverifikasi dan berhasil.
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.registerOfficer(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      officerCode: _codeController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi Petugas berhasil! Selamat bekerja.'),
          backgroundColor: AppColors.statusSelesai,
        ),
      );
      context.go(AppRoutes.officerHome);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registrasi gagal.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.primary),
      ),
      body: LoadingOverlay(
        isLoading: authProvider.isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Gambar Ilustrasi Registrasi
                  Image.asset(
                    'Asset/signup_image.png',
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  
                  // 2. Judul Halaman
                  const Text(
                    'Daftar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Silahkan daftar untuk menjadi petugas',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // 3. Nama Lengkap Field (Ikon Person)
                  CustomTextField(
                    controller: _nameController,
                    labelText: AppStrings.nameLabel,
                    hintText: 'Nama Lengkap',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: Validators.validateRequired,
                  ),
                  const SizedBox(height: 16),

                  // 4. Nomor Telepon Seluler Field (Ikon Phone)
                  CustomTextField(
                    controller: _phoneController,
                    labelText: 'Nomer Telepon Seluler',
                    hintText: 'Nomer Telepon Seluler',
                    prefixIcon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validateRequired,
                  ),
                  const SizedBox(height: 16),

                  // 5. Email Field (Ikon Email)
                  CustomTextField(
                    controller: _emailController,
                    labelText: AppStrings.emailLabel,
                    hintText: 'Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // 6. Kode Verifikasi Petugas (Ikon Key)
                  CustomTextField(
                    controller: _codeController,
                    labelText: AppStrings.officerCodeLabel,
                    hintText: 'Kode Verifikasi Petugas',
                    prefixIcon: Icons.vpn_key_rounded,
                    validator: Validators.validateRequired,
                  ),
                  const SizedBox(height: 16),

                  // 7. Password Field (Ikon Fingerprint)
                  CustomTextField(
                    controller: _passwordController,
                    labelText: AppStrings.passwordLabel,
                    hintText: 'Password',
                    prefixIcon: Icons.fingerprint_rounded,
                    isPassword: true,
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 16),

                  // 8. Konfirmasi Password Field (Ikon Fingerprint)
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Konfirmasi Password',
                    hintText: 'Konfirmasi Password',
                    prefixIcon: Icons.fingerprint_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: (val) => Validators.validateConfirmPassword(
                      val,
                      _passwordController.text,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 9. Tombol DAFTAR (Pill-shaped, background biru muda pastel, teks biru)
                  ElevatedButton(
                    onPressed: _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8F0FE),
                      foregroundColor: AppColors.primary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text(
                      'DAFTAR',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 10. Divider / "atau"
                  const Text(
                    'atau',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // 11. Tautan Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun ?',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
