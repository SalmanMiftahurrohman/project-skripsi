import 'dart:convert';
import 'dart:io';
import '../models/complaint_model.dart';
import '../services/firestore_service.dart';

/// Repositori [ComplaintRepository] mengelola logika penyimpanan, pembaruan, dan pengambilan data 
/// pengaduan sampah ([ComplaintModel]) dari database Firestore serta penanganan gambar dalam base64.
class ComplaintRepository {
  /// Sumber data penyimpanan Cloud Firestore.
  final FirestoreService _firestoreService;

  /// Membuat konstruktor [ComplaintRepository] dengan ketergantungan pada [FirestoreService].
  ComplaintRepository(this._firestoreService);

  /// Membuat dokumen pengaduan baru di Firestore.
  Future<void> createComplaint(ComplaintModel complaint) async {
    await _firestoreService.setData(
      path: 'complaints/${complaint.id}',
      data: complaint.toMap(),
    );
  }

  /// Mengonversi file foto laporan lokal menjadi data URL berbasis Base64.
  /// 
  /// Menerima parameter [file] foto laporan dan [userId] pelapor.
  /// Pengubahan ke Base64 ini dirancang untuk mem-bypass keterbatasan Firebase Storage default/gratisan.
  /// Mengembalikan string data URL Base64, atau URL gambar placeholder default jika terjadi error.
  Future<String> uploadComplaintImage(File file, String userId) async {
    try {
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64Str';
    } catch (e) {
      // Menggunakan gambar placeholder tumpukan sampah dari Unsplash jika terjadi kegagalan
      return 'https://images.unsplash.com/photo-1618477388954-7852f32655ec?q=80&w=600&auto=format&fit=crop';
    }
  }

  /// Mengonversi file bukti pengerjaan petugas lapangan menjadi data URL berbasis Base64.
  /// 
  /// Menerima parameter [file] bukti foto dan [complaintId] pengaduan terkait.
  /// Mengembalikan string data URL Base64, atau URL gambar placeholder default jika terjadi error.
  Future<String> uploadEvidenceImage(File file, String complaintId) async {
    try {
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64Str';
    } catch (e) {
      // Menggunakan gambar placeholder jalanan/taman bersih dari Unsplash jika terjadi kegagalan
      return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=600&auto=format&fit=crop';
    }
  }

  /// Memperbarui sebagian kolom (fields) data pengaduan pada dokumen Firestore berdasarkan [id].
  Future<void> updateComplaintFields(String id, Map<String, dynamic> updates) async {
    await _firestoreService.setData(
      path: 'complaints/$id',
      data: updates,
      merge: true,
    );
  }

  /// Mendapatkan real-time [Stream] daftar pengaduan milik pengguna tertentu ([userId]).
  /// 
  /// Hasil daftar diurutkan berdasarkan waktu pembuatan terbaru ([ComplaintModel.createdAt]).
  Stream<List<ComplaintModel>> getComplaintsStream(String userId) {
    return _firestoreService.collectionStream(
      path: 'complaints',
      queryBuilder: (query) => query
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true),
    ).map((snapshot) {
      return snapshot.docs.map((doc) {
        return ComplaintModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Mendapatkan real-time [Stream] berisi seluruh daftar pengaduan yang ada di dalam sistem (untuk Petugas & Admin).
  /// 
  /// Hasil daftar diurutkan berdasarkan waktu pembuatan terbaru ([ComplaintModel.createdAt]).
  Stream<List<ComplaintModel>> getAllComplaintsStream() {
    return _firestoreService.collectionStream(
      path: 'complaints',
      queryBuilder: (query) => query.orderBy('createdAt', descending: true),
    ).map((snapshot) {
      return snapshot.docs.map((doc) {
        return ComplaintModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Mengambil data dokumen pengaduan tunggal secara asinkron berdasarkan [id].
  /// Mengembalikan objek [ComplaintModel] atau `null` jika dokumen tidak ditemukan.
  Future<ComplaintModel?> getComplaintById(String id) async {
    final snap = await _firestoreService.getDocument(path: 'complaints/$id');
    if (snap.exists && snap.data() != null) {
      return ComplaintModel.fromMap(snap.data()!, id);
    }
    return null;
  }
}
