import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';
import '../repositories/complaint_repository.dart';
import '../services/firestore_service.dart';
import '../services/offline_sync_service.dart';

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

  /// Daftar ID laporan pengaduan (bukti selesai) yang saat ini masih dalam antrean sinkronisasi offline.
  Set<String> _pendingSyncIds = {};

  /// Daftar laporan pengaduan baru yang dibuat secara offline dan tertunda sinkronisasi.
  List<OfflineComplaintItem> _pendingComplaints = [];

  /// Langganan (subscription) aliran data real-time pengaduan dari Firestore.
  StreamSubscription<List<ComplaintModel>>? _complaintsSubscription;

  /// Mendapatkan daftar pengaduan sampah.
  List<ComplaintModel> get complaints => _complaints;

  /// Mendapatkan status loading.
  bool get isLoading => _isLoading;

  /// Mendapatkan pesan error/kesalahan terakhir.
  String? get errorMessage => _errorMessage;

  /// Mendapatkan kumpulan ID laporan yang tertunda sinkronisasi.
  Set<String> get pendingSyncIds => _pendingSyncIds;

  /// Mendapatkan daftar pengaduan baru offline yang tertunda sinkronisasi.
  List<OfflineComplaintItem> get pendingComplaints => _pendingComplaints;

  /// Mengecek apakah suatu pengaduan sedang dalam status tertunda sinkronisasi.
  bool isPendingSync(String complaintId) => _pendingSyncIds.contains(complaintId);

  /// Memuat antrean offline dari penyimpanan lokal untuk mengetahui ID mana saja yang tertunda sinkronisasi.
  Future<void> loadOfflineQueue() async {
    final queue = await OfflineSyncService.getQueue();
    _pendingSyncIds = queue.map((item) => item.complaintId).toSet();

    _pendingComplaints = await OfflineSyncService.getComplaintQueue();
    notifyListeners();
  }

  /// Sinkronisasi seluruh antrean offline secara otomatis (baik antrean laporan selesai maupun laporan baru)
  Future<void> syncOfflineQueue() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Sinkronkan antrean bukti penyelesaian (petugas)
      await OfflineSyncService.syncQueue(
        onItemSynced: (id, success) {
          if (success) {
            _pendingSyncIds.remove(id);
          }
        },
      );

      // 2. Sinkronkan antrean pembuatan laporan baru (masyarakat)
      await OfflineSyncService.syncComplaintQueue(
        onItemSynced: (id, success) {
          if (success) {
            _pendingComplaints.removeWhere((item) => item.id == id);
          }
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mendengarkan daftar pengaduan secara real-time berdasarkan [userId] pengirim (untuk versi Masyarakat).
  void listenToUserComplaints(String userId) {
    _isLoading = true;
    _errorMessage = null;
    loadOfflineQueue();
    
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
    loadOfflineQueue();
    
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
  /// Mendukung pembuatan laporan secara offline. Jika offline, laporan akan diantrekan secara lokal.
  /// Mengembalikan `true` jika berhasil disimpan (online atau antrean offline).
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

    final isOnline = await OfflineSyncService.hasInternetConnection();

    if (!isOnline) {
      try {
        final complaintId = FirebaseFirestore.instance.collection('complaints').doc().id;
        await OfflineSyncService.addToComplaintQueue(
          id: complaintId,
          userId: userId,
          title: title,
          description: description,
          category: category,
          imageFile: imageFile,
          latitude: latitude,
          longitude: longitude,
          address: address,
        );

        _pendingComplaints.add(OfflineComplaintItem(
          id: complaintId,
          userId: userId,
          title: title,
          description: description,
          category: category,
          localImagePath: imageFile.path,
          latitude: latitude,
          longitude: longitude,
          address: address,
          createdAt: DateTime.now(),
        ));

        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        _errorMessage = 'Gagal menyimpan laporan baru secara offline: $e';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }

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
      // Jika unggahan/koneksi gagal saat proses online, alihkan ke antrean offline
      try {
        final complaintId = FirebaseFirestore.instance.collection('complaints').doc().id;
        await OfflineSyncService.addToComplaintQueue(
          id: complaintId,
          userId: userId,
          title: title,
          description: description,
          category: category,
          imageFile: imageFile,
          latitude: latitude,
          longitude: longitude,
          address: address,
        );

        _pendingComplaints.add(OfflineComplaintItem(
          id: complaintId,
          userId: userId,
          title: title,
          description: description,
          category: category,
          localImagePath: imageFile.path,
          latitude: latitude,
          longitude: longitude,
          address: address,
          createdAt: DateTime.now(),
        ));

        _errorMessage = 'Gagal mengirim online ($e). Laporan disimpan dalam antrean offline.';
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (_) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
        return false;
      }
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
  /// Mendukung penyelesaian secara offline jika koneksi internet terputus.
  /// Mengembalikan `true` jika berhasil disimpan (online atau antrean offline).
  Future<bool> resolveComplaint(String complaintId, File evidenceFile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final isOnline = await OfflineSyncService.hasInternetConnection();

    if (!isOnline) {
      try {
        await OfflineSyncService.addToQueue(
          complaintId: complaintId,
          imageFile: evidenceFile,
        );
        _pendingSyncIds.add(complaintId);
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        _errorMessage = 'Gagal menyimpan penyelesaian secara offline: $e';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }

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
      // Jika terjadi kesalahan jaringan saat mengunggah, alihkan ke antrean offline
      try {
        await OfflineSyncService.addToQueue(
          complaintId: complaintId,
          imageFile: evidenceFile,
        );
        _pendingSyncIds.add(complaintId);
        _errorMessage = 'Gagal mengunggah online ($e). Laporan disimpan dalam antrean offline.';
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (_) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
        return false;
      }
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
