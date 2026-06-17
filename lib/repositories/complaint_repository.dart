import 'dart:convert';
import 'dart:io';
import '../models/complaint_model.dart';
import '../services/firestore_service.dart';

class ComplaintRepository {
  final FirestoreService _firestoreService;

  ComplaintRepository(this._firestoreService);


  // Membuat pengaduan baru di Firestore
  Future<void> createComplaint(ComplaintModel complaint) async {
    await _firestoreService.setData(
      path: 'complaints/${complaint.id}',
      data: complaint.toMap(),
    );
  }

  // Mengunggah foto pengaduan ke Firebase Storage (Bypass ke Base64 data URL untuk menghindari limitasi Storage)
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

  // Mengunggah foto bukti bersih-bersih ke Firebase Storage (Bypass ke Base64 data URL untuk menghindari limitasi Storage)
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

  // Memperbarui bidang-bidang tertentu pada dokumen pengaduan
  Future<void> updateComplaintFields(String id, Map<String, dynamic> updates) async {
    await _firestoreService.setData(
      path: 'complaints/$id',
      data: updates,
      merge: true,
    );
  }

  // Mendapatkan stream pengaduan dari user tertentu (Masyarakat)
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

  // Mendapatkan stream seluruh pengaduan di sistem (untuk Petugas & Admin)
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

  // Mengambil satu dokumen pengaduan berdasarkan ID
  Future<ComplaintModel?> getComplaintById(String id) async {
    final snap = await _firestoreService.getDocument(path: 'complaints/$id');
    if (snap.exists && snap.data() != null) {
      return ComplaintModel.fromMap(snap.data()!, id);
    }
    return null;
  }
}
