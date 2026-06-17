import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository(
    AuthService(),
    FirestoreService(),
  );

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;
  
  List<UserModel> _users = [];
  StreamSubscription<List<UserModel>>? _usersSubscription;

  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  String? get userRole => _userModel?.role;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get users => _users;

  // Inisialisasi status user saat aplikasi dibuka
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

  // Login
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

  // Register Masyarakat
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

  // Register Petugas
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

  // Lupa Password
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

  // Logout
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

  // Pesan error khusus foto (terpisah dari errorMessage utama)
  String? _photoErrorMessage;
  String? get photoErrorMessage => _photoErrorMessage;

  // Update Profil Pengguna
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

  void clearError() {

    _errorMessage = null;
    notifyListeners();
  }

  // Helper untuk merapikan pesan error Firebase Auth
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
