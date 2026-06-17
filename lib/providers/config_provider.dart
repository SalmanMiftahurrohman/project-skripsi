import 'package:flutter/material.dart';
import '../repositories/config_repository.dart';
import '../services/firestore_service.dart';

class ConfigProvider extends ChangeNotifier {
  final ConfigRepository _configRepository = ConfigRepository(
    FirestoreService(),
  );

  bool _isLoading = false;
  String? _officerCode;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get officerCode => _officerCode;
  String? get errorMessage => _errorMessage;

  // Membaca kode verifikasi petugas dari Firestore
  Future<void> fetchOfficerCode() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _officerCode = await _configRepository.getOfficerCode();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mengubah kode verifikasi petugas di Firestore
  Future<bool> updateOfficerCode(String newCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _configRepository.updateOfficerCode(newCode);
      _officerCode = newCode;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
