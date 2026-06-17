import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthRepository {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthRepository(
    this._authService,
    this._firestoreService,
  );


  // Login dengan email & password, kemudian ambil data user dari Firestore
  Future<UserModel?> login(String email, String password) async {
    final cred = await _authService.signInWithEmailAndPassword(email, password);
    if (cred.user != null) {
      return await getUserProfile(cred.user!.uid);
    }
    return null;
  }

  // Mengambil profil pengguna dari Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    final snap = await _firestoreService.getDocument(path: 'users/$uid');
    if (snap.exists && snap.data() != null) {
      return UserModel.fromMap(snap.data()!, uid);
    }
    return null;
  }

  // Update profil pengguna (nama, telepon, tanggal lahir, pekerjaan, alamat, foto)
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


  // Registrasi Akun Masyarakat (Citizen)
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

  // Registrasi Akun Petugas (Officer) dengan verifikasi kode khusus
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

  // Sign out
  Future<void> logout() async {
    await _authService.signOut();
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  // Mengambil stream semua pengguna dari Firestore
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
