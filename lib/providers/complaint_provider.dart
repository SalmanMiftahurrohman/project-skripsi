import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';
import '../repositories/complaint_repository.dart';
import '../services/firestore_service.dart';

/// Penyedia state [ComplaintProvider] mengelola status dan aliran data pengaduan sampah.
/// 
/// Ini memfasilitasi pembuatan, pembaruan status, penyelesaian pengaduan,
/// dan pengamatan aliran data real-time baik untuk peran Masyarakat maupun Petugas/Admin.
class ComplaintProvider extends ChangeNotifier {
  /// Instansiasi [ComplaintRepository] sebagai sumber penanganan data pengaduan.
  final ComplaintRepository _complaintRepository = ComplaintRepository(
    FirestoreService(),
  );

  /// Daftar lokal laporan pengaduan sampah yang sedang dimuat.
  List<ComplaintModel> _complaints = [];

  /// Menunjukkan status pemuatan data pengaduan.
  bool _isLoading = false;

  /// Menyimpan pesan kesalahan/error jika ada proses pengambilan atau modifikasi data yang gagal.
  String? _errorMessage;

  /// Langganan (subscription) aliran data real-time pengaduan dari Firestore.
  StreamSubscription<List<ComplaintModel>>? _complaintsSubscription;

  /// Mendapatkan daftar pengaduan sampah.
  List<ComplaintModel> get complaints => _complaints;

  /// Mendapatkan status loading.
  bool get isLoading => _isLoading;

  /// Mendapatkan pesan error/kesalahan terakhir.
  String? get errorMessage => _errorMessage;

  /// Mendengarkan daftar pengaduan secara real-time berdasarkan [userId] pengirim (untuk versi Masyarakat).
  void listenToUserComplaints(String userId) {
    _isLoading = true;
    _errorMessage = null;
    
    _complaintsSubscription?.cancel();
    _complaintsSubscription = _complaintRepository.getComplaintsStream(userId).listen(
      (data) {
        _complaints = data;
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

  /// Mendengarkan seluruh daftar pengaduan secara real-time dari database (untuk versi Petugas & Admin).
  void listenToAllComplaints() {
    _isLoading = true;
    _errorMessage = null;
    
    _complaintsSubscription?.cancel();
    _complaintsSubscription = _complaintRepository.getAllComplaintsStream().listen(
      (data) {
        _complaints = data;
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

  /// Membuat pengaduan laporan penumpukan sampah baru.
  /// 
  /// Alur proses: mengunggah [imageFile] foto ke penyimpanan base64 data URL,
  /// menghasilkan ID unik laporan, membuat [ComplaintModel], lalu menyimpannya ke Firestore.
  /// Mengembalikan `true` jika berhasil.
  Future<bool> createComplaint({
    required String userId,
    required String title,
    required String description,
    required String category,
    required File imageFile,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Upload gambar ke Firebase Storage terlebih dahulu
      final imageUrl = await _complaintRepository.uploadComplaintImage(imageFile, userId);

      // 2. Generate ID dokumen kustom di Firestore
      final complaintId = FirebaseFirestore.instance.collection('complaints').doc().id;

      // 3. Buat model pengaduan
      final newComplaint = ComplaintModel(
        id: complaintId,
        userId: userId,
        title: title,
        description: description,
        imageUrl: imageUrl,
        latitude: latitude,
        longitude: longitude,
        address: address,
        category: category,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      // 4. Simpan ke Firestore
      await _complaintRepository.createComplaint(newComplaint);

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

  /// Memperbarui status penanganan laporan pengaduan sampah ([newStatus]).
  /// 
  /// Mendukung pencatatan waktu diproses ([processedAt]) jika status berubah menjadi 'Diproses',
  /// serta pencatatan alasan penolakan ([rejectionReason]) jika status berubah menjadi 'Ditolak'.
  /// Mengembalikan `true` jika berhasil.
  Future<bool> updateStatus(String complaintId, String newStatus, {String? rejectionReason}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> updates = {
        'status': newStatus,
      };

      if (newStatus == 'Diproses') {
        updates['processedAt'] = Timestamp.now();
      }

      if (newStatus == 'Ditolak' && rejectionReason != null) {
        updates['rejectionReason'] = rejectionReason;
        updates['resolvedAt'] = Timestamp.now();
      }

      await _complaintRepository.updateComplaintFields(complaintId, updates);
      
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

  /// Menyelesaikan laporan pengaduan sampah dengan status 'Selesai' dan melampirkan foto bukti pengerjaan ([evidenceFile]).
  /// 
  /// Mengonversi foto bukti menjadi Base64, mengubah status laporan, dan menyimpan data ke Firestore.
  /// Mengembalikan `true` jika berhasil.
  Future<bool> resolveComplaint(String complaintId, File evidenceFile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Unggah bukti foto ke Storage
      final evidenceImageUrl = await _complaintRepository.uploadEvidenceImage(evidenceFile, complaintId);

      // 2. Perbarui status menjadi Selesai dan simpan URL bukti & timestamp
      final Map<String, dynamic> updates = {
        'status': 'Selesai',
        'resolvedAt': Timestamp.now(),
        'evidenceImageUrl': evidenceImageUrl,
      };

      await _complaintRepository.updateComplaintFields(complaintId, updates);

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

  /// Mencari laporan pengaduan berdasarkan [id] laporan.
  /// 
  /// Mengecek terlebih dahulu di daftar lokal memori [_complaints]. Jika tidak ditemukan,
  /// fungsi ini akan mengambil dokumen langsung dari Firestore.
  Future<ComplaintModel?> fetchComplaintById(String id) async {
    _isLoading = true;
    _errorMessage = null;
    Future.microtask(() => notifyListeners());

    try {
      // 1. Cek di memori lokal
      if (_complaints.isNotEmpty) {
        final local = _complaints.where((c) => c.id == id);
        if (local.isNotEmpty) {
          _isLoading = false;
          notifyListeners();
          return local.first;
        }
      }
      
      // 2. Jika tidak ada di lokal (misal refresh/deep link), ambil dari Firestore
      final remote = await _complaintRepository.getComplaintById(id);
      _isLoading = false;
      notifyListeners();
      return remote;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Membersihkan pesan error/kesalahan saat ini.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    super.dispose();
  }
}
