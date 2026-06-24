/// Kelas [AppRoutes] menyimpan definisi nama rute (routes) navigasi 
/// yang digunakan oleh router aplikasi GO - SAMPAH untuk mengarahkan pengguna ke layar yang tepat.
class AppRoutes {
  /// Rute untuk layar splash (tampilan awal/loading inisialisasi).
  static const String splash = '/';

  /// Rute untuk layar masuk (login).
  static const String login = '/login';

  /// Rute untuk layar pendaftaran awal (pemilihan role citizen/officer).
  static const String register = '/register';

  /// Rute untuk layar pendaftaran masyarakat (citizen).
  static const String registerCitizen = '/register/citizen';

  /// Rute untuk layar pendaftaran petugas (officer).
  static const String registerOfficer = '/register/officer';

  /// Rute untuk layar pemulihan kata sandi (forgot password).
  static const String forgotPassword = '/forgot-password';

  /// Rute untuk layar utama masyarakat (citizen home).
  static const String citizenHome = '/masyarakat/home';

  /// Rute untuk layar pembuatan pengaduan sampah baru oleh masyarakat.
  static const String citizenCreateComplaint = '/masyarakat/complaint/create';

  /// Rute dinamis untuk layar detail pengaduan sampah bagi masyarakat (memerlukan parameter ID).
  static const String citizenComplaintDetail = '/masyarakat/complaint/:id';

  /// Rute untuk layar profil pengguna (berlaku untuk semua role).
  static const String profile = '/profile';

  /// Rute untuk layar utama petugas (officer home).
  static const String officerHome = '/petugas/home';

  /// Rute dinamis untuk layar detail pengaduan sampah bagi petugas (memerlukan parameter ID).
  static const String officerComplaintDetail = '/petugas/complaint/:id';

  /// Rute untuk dashboard utama admin.
  static const String adminDashboard = '/admin/dashboard';

  /// Rute untuk layar manajemen semua pengaduan di panel admin.
  static const String adminComplaints = '/admin/complaints';

  /// Rute untuk layar manajemen pengguna (masyarakat) di panel admin.
  static const String adminUsers = '/admin/users';

  /// Rute untuk layar manajemen daftar petugas di panel admin.
  static const String adminOfficers = '/admin/officers';

  /// Rute untuk layar pengaturan/konfigurasi sistem di panel admin.
  static const String adminConfig = '/admin/config';

  /// Fungsi pembantu untuk menghasilkan path detail pengaduan masyarakat secara dinamis berdasarkan [id].
  static String getCitizenComplaintDetailPath(String id) => '/masyarakat/complaint/$id';

  /// Fungsi pembantu untuk menghasilkan path detail pengaduan petugas secara dinamis berdasarkan [id].
  static String getOfficerComplaintDetailPath(String id) => '/petugas/complaint/$id';
}
