import 'package:flutter/material.dart';
import '../repositories/config_repository.dart';
import '../services/firestore_service.dart';

/// Penyedia state [ConfigProvider] menangani data konfigurasi aplikasi global, 
/// terutama pemantauan dan pembaruan kode verifikasi registrasi petugas lapangan.
class ConfigProvider extends ChangeNotifier {
  /// Instansiasi [ConfigRepository] untuk memproses query konfigurasi.
  final ConfigRepository _configRepository = ConfigRepository(
    FirestoreService(),
  );

  /// Status loading pemicu UI indicator.
  bool _isLoading = false;

  /// Kode verifikasi petugas aktif yang dimuat dari Firestore.
  String? _officerCode;

  /// Pesan error jika terjadi kegagalan pengambilan atau pembaruan kode.
  String? _errorMessage;

  /// Mendapatkan status pemuatan data.
  bool get isLoading => _isLoading;

  /// Mendapatkan kode verifikasi petugas saat ini.
  String? get officerCode => _officerCode;

  /// Mendapatkan pesan error/kesalahan terakhir.
  String? get errorMessage => _errorMessage;

  /// Mengambil kode verifikasi petugas dari database Firestore secara asinkron.
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

  /// Memperbarui kode verifikasi petugas dengan [newCode] baru di Firestore.
  /// 
  /// Mengembalikan `true` jika pembaruan berhasil.
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
