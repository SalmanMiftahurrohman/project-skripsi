import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

/// Repositori [ConfigRepository] bertanggung jawab untuk mengelola konfigurasi aplikasi secara global
/// yang disimpan dalam Firestore, seperti kode pendaftaran untuk petugas lapangan.
class ConfigRepository {
  /// Sumber data penyimpanan Firestore.
  final FirestoreService _firestoreService;

  /// Membuat konstruktor [ConfigRepository] dengan ketergantungan pada [FirestoreService].
  ConfigRepository(this._firestoreService);

  /// Mengambil kode verifikasi pendaftaran petugas yang tersimpan di sistem Firestore (`config/officer_code`).
  /// Mengembalikan string kode, atau `null` jika tidak ditemukan.
  Future<String?> getOfficerCode() async {
    final snap = await _firestoreService.getDocument(path: 'config/officer_code');
    if (snap.exists && snap.data() != null) {
      return snap.data()!['code'] as String?;
    }
    return null;
  }

  /// Memperbarui kode verifikasi pendaftaran petugas lapangan dengan [newCode] baru 
  /// dan mencatat tanggal pembaruannya di Firestore.
  Future<void> updateOfficerCode(String newCode) async {
    await _firestoreService.setData(
      path: 'config/officer_code',
      data: {
        'code': newCode,
        'updatedAt': Timestamp.now(),
      },
    );
  }
}

