import '../constants/app_strings.dart';

/// Kelas [Validators] berisi sekumpulan fungsi utilitas statis untuk memvalidasi input form
/// seperti email, kata sandi, konfirmasi kata sandi, dan input wajib (required fields).
class Validators {
  /// Memvalidasi format email.
  /// 
  /// Mengembalikan pesan error dari [AppStrings.fieldRequired] jika email kosong,
  /// [AppStrings.invalidEmail] jika format email tidak sesuai dengan ekspresi reguler (Regex),
  /// atau `null` jika email valid.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    // Regular expression for email validation
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  /// Memvalidasi kekuatan minimal kata sandi.
  /// 
  /// Mengembalikan pesan error dari [AppStrings.fieldRequired] jika kata sandi kosong,
  /// [AppStrings.invalidPassword] jika panjang karakter kurang dari 6,
  /// atau `null` jika kata sandi memenuhi batas minimum.
  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value.length < 6) {
      return AppStrings.invalidPassword;
    }
    return null;
  }

  /// Memvalidasi kesamaan konfirmasi kata sandi dengan kata sandi utama.
  /// 
  /// Menerima parameter [value] (konfirmasi kata sandi) dan [password] (kata sandi utama).
  /// Mengembalikan pesan error dari [AppStrings.fieldRequired] jika kosong,
  /// [AppStrings.passwordNotMatch] jika nilai konfirmasi tidak sama dengan [password],
  /// atau `null` jika cocok.
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value != password) {
      return AppStrings.passwordNotMatch;
    }
    return null;
  }

  /// Memvalidasi bahwa input field wajib diisi dan tidak boleh kosong.
  /// 
  /// Mengembalikan pesan error dari [AppStrings.fieldRequired] jika nilai kosong atau hanya spasi,
  /// atau `null` jika terisi.
  static String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    return null;
  }
}
