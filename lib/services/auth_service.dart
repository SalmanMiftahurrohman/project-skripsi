import 'package:firebase_auth/firebase_auth.dart';

/// Layanan [AuthService] bertanggung jawab atas interaksi langsung dengan Firebase Authentication.
/// Layanan ini memfasilitasi login, register, logout, pemantauan status auth, dan reset password.
class AuthService {
  /// Instance [FirebaseAuth] untuk mengelola sesi otentikasi.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mendapatkan data user yang saat ini sedang login ([User]).
  /// Mengembalikan `null` jika tidak ada pengguna yang aktif dalam sesi saat ini.
  User? get currentUser => _auth.currentUser;

  /// Stream yang mendengarkan perubahan status otentikasi pengguna secara real-time.
  /// Memancarkan objek [User] baru saat login, logout, atau saat token kedaluwarsa.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Melakukan otentikasi masuk pengguna menggunakan email dan kata sandi.
  /// 
  /// Menerima parameter [email] dan [password].
  /// Mengembalikan [UserCredential] jika otentikasi berhasil.
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Mendaftarkan pengguna baru menggunakan email dan kata sandi di Firebase Authentication.
  /// 
  /// Menerima parameter [email] dan [password].
  /// Mengembalikan [UserCredential] yang berisi informasi akun baru.
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Mengeluarkan pengguna dari sesi aktif saat ini dan menghapus token otentikasi lokal.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Mengirimkan email instruksi pemulihan/reset kata sandi ke alamat [email] yang didaftarkan.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
