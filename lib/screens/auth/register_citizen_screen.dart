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

class RegisterCitizenScreen extends StatefulWidget {
  const RegisterCitizenScreen({super.key});

  @override
  State<RegisterCitizenScreen> createState() => _RegisterCitizenScreenState();
}

class _RegisterCitizenScreenState extends State<RegisterCitizenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.registerCitizen(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil! Selamat datang.'),
          backgroundColor: AppColors.statusSelesai,
        ),
      );
      context.go(AppRoutes.citizenHome);
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
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  
                  // 2. Judul Halaman
                  const Text(
                    'Mari Bergabung',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Buat akun untuk melakukan pelaporan',
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

                  // 4. Nomor Telepon Field (Ikon Phone)
                  CustomTextField(
                    controller: _phoneController,
                    labelText: 'Nomor Telepon',
                    hintText: 'Nomor Telepon',
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

                  // 6. Password Field (Ikon Fingerprint)
                  CustomTextField(
                    controller: _passwordController,
                    labelText: AppStrings.passwordLabel,
                    hintText: 'Password',
                    prefixIcon: Icons.fingerprint_rounded,
                    isPassword: true,
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 16),

                  // 7. Konfirmasi Password Field (Ikon Fingerprint)
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Konfimasi Password',
                    hintText: 'Konfimasi Password',
                    prefixIcon: Icons.fingerprint_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: (val) => Validators.validateConfirmPassword(
                      val,
                      _passwordController.text,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 8. Tombol DAFTAR (Pill-shaped, background biru muda pastel, teks biru)
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

                  // 9. Divider / "atau"
                  const Text(
                    'atau',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // 10. Tautan Login
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
                          'Masuk',
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
