import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Penyedia state [AuthProvider] mengelola kondisi otentikasi pengguna secara global di aplikasi.
/// 
/// Menggunakan ChangeNotifier untuk menginformasikan widget ketika terjadi perubahan
/// pada state loading, user login, data profil, list user, atau pesan error.
class AuthProvider extends ChangeNotifier {
  /// Instansiasi [AuthRepository] sebagai penghubung data auth.
  final AuthRepository _authRepository = AuthRepository(
    AuthService(),
    FirestoreService(),
  );

  /// User aktif dari Firebase Auth ([User]).
  User? _user;

  /// Profil pengguna yang didapatkan dari database Firestore ([UserModel]).
  UserModel? _userModel;

  /// Status loading untuk memicu indikator loading di antarmuka UI.
  bool _isLoading = false;

  /// Pesan error/kesalahan jika terjadi kegagalan proses otentikasi.
  String? _errorMessage;
  
  /// Daftar semua profil pengguna terdaftar (untuk konsumsi panel Admin).
  List<UserModel> _users = [];

  /// Langganan (subscription) aliran data real-time daftar pengguna dari Firestore.
  StreamSubscription<List<UserModel>>? _usersSubscription;

  /// Mendapatkan user dari Firebase Auth.
  User? get user => _user;

  /// Mendapatkan data profil detail pengguna ([UserModel]).
  UserModel? get userModel => _userModel;

  /// Mendapatkan peran/role pengguna saat ini (contoh: 'masyarakat', 'petugas', 'admin').
  String? get userRole => _userModel?.role;

  /// Mendapatkan status apakah proses otentikasi sedang loading.
  bool get isLoading => _isLoading;

  /// Mendapatkan pesan error/kesalahan otentikasi terakhir.
  String? get errorMessage => _errorMessage;

  /// Mendapatkan daftar semua pengguna terdaftar.
  List<UserModel> get users => _users;

  /// Menginisialisasi status masuk pengguna saat pertama kali aplikasi dibuka.
  /// 
  /// Mengecek apakah ada pengguna yang aktif di Firebase Auth, lalu memuat profilnya dari Firestore.
  Future<void> initializeUser() async {
    _isLoading = true;
    _errorMessage = null;
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _user = currentUser;
        _userModel = await _authRepository.getUserProfile(currentUser.uid);
      } else {
        _user = null;
        _userModel = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Masuk (login) ke aplikasi dengan menggunakan [email] dan [password].
  /// 
  /// Mengembalikan nilai `true` jika login berhasil dan memuat data profil pengguna.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loggedInUser = await _authRepository.login(email, password);
      if (loggedInUser != null) {
        _userModel = loggedInUser;
        _user = FirebaseAuth.instance.currentUser;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Data profil pengguna tidak ditemukan.');
      }
    } catch (e) {
      _errorMessage = _cleanExceptionMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mendaftarkan akun pengguna baru dengan peran 'masyarakat' (Citizen).
  /// 
  /// Menerima parameter [email], [password], [name] (nama lengkap), dan [phoneNumber] (telepon).
  /// Mengembalikan `true` jika pendaftaran akun berhasil.
  Future<bool> registerCitizen({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newUser = await _authRepository.registerCitizen(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
      );
      _userModel = newUser;
      _user = FirebaseAuth.instance.currentUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanExceptionMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mendaftarkan akun petugas baru (Officer) ke dalam sistem.
  /// 
  /// Memerlukan kode verifikasi rahasia [officerCode] untuk memvalidasi peran petugas.
  /// Mengembalikan `true` jika kode benar dan pembuatan akun berhasil.
  Future<bool> registerOfficer({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String officerCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newUser = await _authRepository.registerOfficer(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
        officerCode: officerCode,
      );
      _userModel = newUser;
      _user = FirebaseAuth.instance.currentUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanExceptionMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mengirimkan email pemulihan/reset kata sandi ke [email] yang dituju.
  /// 
  /// Mengembalikan `true` jika berhasil dikirim.
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanExceptionMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mengeluarkan (logout) pengguna dari sistem dan menghapus semua cache user state.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.logout();
      _user = null;
      _userModel = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mengaktifkan pendengar real-time untuk memantau data seluruh pengguna terdaftar (untuk panel admin).
  void listenToAllUsers() {
    _isLoading = true;
    _errorMessage = null;
    
    _usersSubscription?.cancel();
    _usersSubscription = _authRepository.getUsersStream().listen(
      (data) {
        _users = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Pesan kesalahan khusus untuk pengelolaan foto.
  String? _photoErrorMessage;

  /// Mendapatkan pesan error/kesalahan pembaruan foto terakhir.
  String? get photoErrorMessage => _photoErrorMessage;

  /// Memperbarui data profil pengguna saat ini.
  /// 
  /// Menerima parameter profil baru: [name], [phoneNumber], [birthDate], [occupation], dan [address].
  /// Mengembalikan `true` jika pembaruan data Firestore berhasil.
  Future<bool> updateProfile({
    required String name,
    required String phoneNumber,
    required String birthDate,
    required String occupation,
    required String address,
  }) async {
    if (_userModel == null) return false;

    _isLoading = true;
    _errorMessage = null;
    _photoErrorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _authRepository.updateProfile(
        currentUser: _userModel!,
        name: name,
        phoneNumber: phoneNumber,
        birthDate: birthDate,
        occupation: occupation,
        address: address,
      );
      _userModel = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Membersihkan pesan error/kesalahan otentikasi saat ini.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Menerjemahkan dan membersihkan pesan pengecualian Firebase Auth [msg] ke dalam bahasa Indonesia.
  String _cleanExceptionMessage(String msg) {
    if (msg.contains('user-not-found')) {
      return 'Email tidak terdaftar.';
    } else if (msg.contains('wrong-password')) {
      return 'Password salah.';
    } else if (msg.contains('email-already-in-use')) {
      return 'Email sudah terdaftar.';
    } else if (msg.contains('invalid-credential')) {
      return 'Email atau password salah.';
    } else if (msg.contains('Exception:')) {
      return msg.replaceAll('Exception: ', '');
    }
    return msg;
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    super.dispose();
  }
}
