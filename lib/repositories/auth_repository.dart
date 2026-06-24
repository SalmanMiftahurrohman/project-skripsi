import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Repositori [AuthRepository] menangani logika bisnis tingkat tinggi untuk otentikasi pengguna.
/// Kelas ini menggabungkan penggunaan [AuthService] untuk kredensial Firebase Auth
/// dan [FirestoreService] untuk sinkronisasi profil pengguna ke Cloud Firestore.
class AuthRepository {
  /// Sumber data otentikasi Firebase.
  final AuthService _authService;

  /// Sumber data penyimpanan data pengguna di Firestore.
  final FirestoreService _firestoreService;

  /// Membuat konstruktor [AuthRepository] dengan ketergantungan layanan otentikasi dan basis data.
  AuthRepository(
    this._authService,
    this._firestoreService,
  );

  /// Melakukan login ke aplikasi.
  /// 
  /// Menerima parameter [email] dan [password]. Jika proses login sukses di Firebase Auth,
  /// fungsi ini akan mengambil profil pengguna dari Firestore via [getUserProfile] dan mengembalikannya.
  Future<UserModel?> login(String email, String password) async {
    final cred = await _authService.signInWithEmailAndPassword(email, password);
    if (cred.user != null) {
      return await getUserProfile(cred.user!.uid);
    }
    return null;
  }

  /// Mengambil data profil lengkap pengguna ([UserModel]) dari Firestore berdasarkan [uid] pengguna.
  /// Mengembalikan `null` jika dokumen profil tidak ditemukan.
  Future<UserModel?> getUserProfile(String uid) async {
    final snap = await _firestoreService.getDocument(path: 'users/$uid');
    if (snap.exists && snap.data() != null) {
      return UserModel.fromMap(snap.data()!, uid);
    }
    return null;
  }

  /// Memperbarui informasi profil pengguna pada Firestore dan mengembalikan objek [UserModel] baru yang diperbarui.
  /// 
  /// Parameter yang dapat diperbarui meliputi [name] (nama), [phoneNumber] (nomor telepon), 
  /// [birthDate] (tanggal lahir), [occupation] (pekerjaan), dan [address] (alamat).
  Future<UserModel> updateProfile({
    required UserModel currentUser,
    required String name,
    required String phoneNumber,
    required String birthDate,
    required String occupation,
    required String address,
  }) async {
    final updatedUser = currentUser.copyWith(
      name: name,
      phoneNumber: phoneNumber,
      birthDate: birthDate,
      occupation: occupation,
      address: address,
    );

    await _firestoreService.updateData(
      path: 'users/${currentUser.uid}',
      data: {
        'name': name,
        'phoneNumber': phoneNumber,
        'birthDate': birthDate,
        'occupation': occupation,
        'address': address,
      },
    );

    return updatedUser;
  }

  /// Mendaftarkan pengguna baru dengan peran 'masyarakat' (Citizen).
  /// 
  /// Melakukan pendaftaran ke Firebase Auth dengan [email] dan [password], lalu membuat dokumen pengguna
  /// di Firestore berisi [name] dan [phoneNumber] dengan role diset secara otomatis ke `'masyarakat'`.
  Future<UserModel> registerCitizen({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    final cred = await _authService.createUserWithEmailAndPassword(email, password);
    final uid = cred.user!.uid;

    final newUser = UserModel(
      uid: uid,
      email: email,
      name: name,
      role: 'masyarakat',
      phoneNumber: phoneNumber,
      birthDate: '',
      occupation: '',
      address: '',
      createdAt: DateTime.now(),
    );

    await _firestoreService.setData(
      path: 'users/$uid',
      data: newUser.toMap(),
    );

    return newUser;
  }

  /// Mendaftarkan pengguna baru dengan peran 'petugas' (Officer) dengan syarat kode khusus petugas.
  /// 
  /// Memvalidasi terlebih dahulu apakah [officerCode] yang dimasukkan cocok dengan kode sistem yang tersimpan 
  /// di Firestore (`config/officer_code`). Jika cocok, akun dibuat di Firebase Auth dan data profil
  /// disimpan ke Firestore dengan role diset ke `'petugas'`. Melemparkan [Exception] jika kode verifikasi salah atau tidak ditemukan.
  Future<UserModel> registerOfficer({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String officerCode,
  }) async {
    final snap = await _firestoreService.getDocument(path: 'config/officer_code');
    if (!snap.exists || snap.data() == null) {
      throw Exception('Konfigurasi kode verifikasi petugas tidak ditemukan di sistem.');
    }

    final systemCode = snap.data()!['code'] as String?;
    if (systemCode == null || systemCode.trim().isEmpty) {
      throw Exception('Kode verifikasi belum diatur oleh admin.');
    }

    if (systemCode.trim() != officerCode.trim()) {
      throw Exception('Kode verifikasi petugas salah!');
    }

    final cred = await _authService.createUserWithEmailAndPassword(email, password);
    final uid = cred.user!.uid;

    final newUser = UserModel(
      uid: uid,
      email: email,
      name: name,
      role: 'petugas',
      phoneNumber: phoneNumber,
      birthDate: '',
      occupation: '',
      address: '',
      createdAt: DateTime.now(),
    );

    await _firestoreService.setData(
      path: 'users/$uid',
      data: newUser.toMap(),
    );

    return newUser;
  }

  /// Mengeluarkan pengguna (logout) dari sesi aplikasi saat ini.
  Future<void> logout() async {
    await _authService.signOut();
  }

  /// Mengirim instruksi tautan pemulihan kata sandi ke [email] pengguna.
  Future<void> resetPassword(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  /// Mendapatkan data perubahan daftar semua pengguna terdaftar secara real-time.
  /// 
  /// Mengembalikan [Stream] berisi daftar [UserModel] yang diurutkan berdasarkan tanggal pendaftaran terbaru.
  Stream<List<UserModel>> getUsersStream() {
    return _firestoreService.collectionStream(
      path: 'users',
      queryBuilder: (query) => query.orderBy('createdAt', descending: true),
    ).map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
