import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Widget [CustomTextField] menyediakan kustomisasi text field (formulir input teks)
/// dengan dukungan visual bawaan untuk label, ikon prefix, tipe password (dapat disembunyikan/ditampilkan),
/// validasi input, tipe keyboard, serta aksi enter tombol keyboard.
class CustomTextField extends StatefulWidget {
  /// Kontroler teks untuk membaca dan memanipulasi teks input field ([TextEditingController]).
  final TextEditingController controller;

  /// Label teks petunjuk yang melayang saat input aktif.
  final String labelText;

  /// Teks petunjuk abu-abu samar ketika field kosong.
  final String? hintText;

  /// Ikon dekorasi yang tampil di bagian awal (prefix) kolom input.
  final IconData? prefixIcon;

  /// Menandakan apakah input field ditujukan untuk password/kata sandi.
  /// Jika `true`, teks akan disamarkan secara default dan menampilkan tombol toggle visibility.
  final bool isPassword;

  /// Fungsi validator kustom untuk memvalidasi teks yang diinput pengguna.
  final String? Function(String?)? validator;

  /// Tipe layout keyboard virtual perangkat yang sesuai dengan input (contoh: email, nomor telepon, angka).
  final TextInputType keyboardType;

  /// Aksi tombol submit di keyboard (contoh: next untuk pindah field, done untuk selesai).
  final TextInputAction textInputAction;

  /// Jumlah baris tinggi maksimum kolom input teks.
  final int maxLines;

  /// Membuat instance baru dari [CustomTextField].
  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.maxLines,
      style: const TextStyle(fontSize: 16),
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon != null 
            ? Icon(widget.prefixIcon, color: AppColors.primaryLight) 
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }
}
