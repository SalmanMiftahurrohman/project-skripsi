/// Kelas [AppStrings] menyimpan semua teks statis (lokalisasi manual) yang ditampilkan di aplikasi GO - SAMPAH.
class AppStrings {
  /// Nama resmi aplikasi.
  static const String appName = 'GO - SAMPAH';

  /// Slogan/tagline aplikasi yang ditampilkan di layar login/splash.
  static const String appTagline = 'Laporkan Sampah untuk Lingkungan Bersih';

  /// Judul utama halaman login.
  static const String loginTitle = 'Selamat Datang';

  /// Subjudul halaman login yang menjelaskan fungsi aplikasi.
  static const String loginSubtitle = 'Masuk untuk mengadukan penumpukan sampah';

  /// Label untuk input field Email.
  static const String emailLabel = 'Email';

  /// Label untuk input field Password.
  static const String passwordLabel = 'Password';

  /// Label untuk input field Konfirmasi Password pada halaman pendaftaran.
  static const String confirmPasswordLabel = 'Konfirmasi Password';

  /// Label untuk input field Nama Lengkap pengguna.
  static const String nameLabel = 'Nama Lengkap';

  /// Label untuk input field Kode Verifikasi Petugas (untuk pendaftaran petugas).
  static const String officerCodeLabel = 'Kode Verifikasi Petugas';

  /// Teks tombol pendaftaran (Daftar).
  static const String registerButton = 'Daftar';

  /// Teks tombol masuk (Masuk).
  static const String loginButton = 'Masuk';

  /// Teks tombol/tautan lupa kata sandi.
  static const String forgotPasswordButton = 'Lupa Password?';

  /// Teks tombol keluar (Logout).
  static const String logoutButton = 'Keluar';

  /// Representasi teks status pengaduan 'Pending'.
  static const String statusPendingStr = 'Pending';

  /// Representasi teks status pengaduan 'Diterima'.
  static const String statusDiterimaStr = 'Diterima';

  /// Representasi teks status pengaduan 'Terverifikasi'.
  static const String statusTerverifikasiStr = 'Terverifikasi';

  /// Representasi teks status pengaduan 'Diproses'.
  static const String statusDiprosesStr = 'Diproses';

  /// Representasi teks status pengaduan 'Selesai'.
  static const String statusSelesaiStr = 'Selesai';

  /// Pesan error validasi form jika field yang wajib diisi dikosongkan.
  static const String fieldRequired = 'Bagian ini wajib diisi';

  /// Pesan error validasi form jika format email tidak sesuai.
  static const String invalidEmail = 'Format email tidak valid';

  /// Pesan error validasi form jika password kurang dari 6 karakter.
  static const String invalidPassword = 'Password harus minimal 6 karakter';

  /// Pesan error validasi form jika password konfirmasi tidak sama dengan password utama.
  static const String passwordNotMatch = 'Password tidak cocok';

  /// Pesan error validasi form jika kode pendaftaran petugas tidak valid/salah.
  static const String invalidOfficerCode = 'Kode verifikasi petugas tidak valid';
}
