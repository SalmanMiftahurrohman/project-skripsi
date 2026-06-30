import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Item antrean unggahan offline untuk bukti penyelesaian
class OfflineQueueItem {
  final String complaintId;
  final String localImagePath;
  final DateTime resolvedAt;

  OfflineQueueItem({
    required this.complaintId,
    required this.localImagePath,
    required this.resolvedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'complaintId': complaintId,
      'localImagePath': localImagePath,
      'resolvedAt': resolvedAt.toIso8601String(),
    };
  }

  factory OfflineQueueItem.fromMap(Map<String, dynamic> map) {
    return OfflineQueueItem(
      complaintId: map['complaintId'] ?? '',
      localImagePath: map['localImagePath'] ?? '',
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.parse(map['resolvedAt'])
          : DateTime.now(),
    );
  }
}

/// Model data untuk menampung pengaduan sampah baru yang dibuat secara offline.
class OfflineComplaintItem {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String localImagePath;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime createdAt;

  OfflineComplaintItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.localImagePath,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'localImagePath': localImagePath,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OfflineComplaintItem.fromMap(Map<String, dynamic> map) {
    return OfflineComplaintItem(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Kebersihan',
      localImagePath: map['localImagePath'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}

/// Layanan [OfflineSyncService] mengelola antrean pengerjaan pengaduan offline
/// untuk petugas lapangan dan masyarakat. Data disimpan dalam bentuk JSON di direktori dokumen lokal.
class OfflineSyncService {
  static const String _queueFileName = 'offline_queue.json';
  static const String _complaintsQueueFileName = 'offline_complaints_queue.json';
  
  static bool _isSyncing = false;
  static bool _isSyncingComplaints = false;

  /// Mendapatkan status apakah proses sinkronisasi sedang berjalan
  static bool get isSyncing => _isSyncing;
  static bool get isSyncingComplaints => _isSyncingComplaints;

  /// Dapatkan path file berkas antrean `offline_queue.json`
  static Future<File> _getQueueFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, _queueFileName));
  }

  /// Dapatkan path file berkas antrean `offline_complaints_queue.json`
  static Future<File> _getComplaintsQueueFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, _complaintsQueueFileName));
  }

  // ==========================================
  // BAGIAN 1: ANTREAN BUKTI SELESAI (PETUGAS)
  // ==========================================

  /// Membaca seluruh antrean offline dari file lokal
  static Future<List<OfflineQueueItem>> getQueue() async {
    try {
      final file = await _getQueueFile();
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList.map((item) => OfflineQueueItem.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Gagal membaca antrean offline: $e');
      return [];
    }
  }

  /// Menyimpan daftar antrean ke berkas lokal
  static Future<void> _saveQueue(List<OfflineQueueItem> queue) async {
    try {
      final file = await _getQueueFile();
      final contents = json.encode(queue.map((item) => item.toMap()).toList());
      await file.writeAsString(contents);
    } catch (e) {
      debugPrint('Gagal menyimpan antrean offline: $e');
    }
  }

  /// Menambahkan item baru ke antrean offline.
  /// Foto bukti akan disalin ke penyimpanan internal aplikasi agar aman dari pembersihan cache.
  static Future<void> addToQueue({
    required String complaintId,
    required File imageFile,
  }) async {
    try {
      // 1. Salin file ke direktori dokumen aplikasi agar permanen
      final directory = await getApplicationDocumentsDirectory();
      final String extension = p.extension(imageFile.path);
      final String newFileName = 'evidence_$complaintId$extension';
      final String newPath = p.join(directory.path, newFileName);
      
      final File savedImage = await imageFile.copy(newPath);

      // 2. Baca antrean saat ini
      final queue = await getQueue();
      
      // Hapus jika ada kelola complaintId yang sama sebelumnya agar tidak duplikat
      queue.removeWhere((item) => item.complaintId == complaintId);

      // Tambahkan item baru
      queue.add(OfflineQueueItem(
        complaintId: complaintId,
        localImagePath: savedImage.path,
        resolvedAt: DateTime.now(),
      ));

      // 3. Simpan antrean terbaru
      await _saveQueue(queue);
      debugPrint('Laporan $complaintId berhasil masuk antrean offline.');
    } catch (e) {
      debugPrint('Gagal menambahkan ke antrean offline: $e');
      rethrow;
    }
  }

  /// Menghapus item dari antrean offline (beserta berkas gambarnya)
  static Future<void> removeFromQueue(String complaintId) async {
    try {
      final queue = await getQueue();
      final index = queue.indexWhere((item) => item.complaintId == complaintId);
      
      if (index != -1) {
        final item = queue[index];
        final file = File(item.localImagePath);
        if (await file.exists()) {
          await file.delete();
        }
        
        queue.removeAt(index);
        await _saveQueue(queue);
      }
    } catch (e) {
      debugPrint('Gagal menghapus antrean offline untuk $complaintId: $e');
    }
  }

  /// Melakukan sinkronisasi seluruh antrean offline ke Firebase (Storage & Firestore).
  /// Dipanggil secara berkala atau ketika koneksi kembali online.
  static Future<void> syncQueue({
    VoidCallback? onSyncStart,
    Function(String complaintId, bool success)? onItemSynced,
    VoidCallback? onSyncComplete,
  }) async {
    if (_isSyncing) return;
    
    // Periksa koneksi internet terlebih dahulu
    final isOnline = await hasInternetConnection();
    if (!isOnline) {
      debugPrint('Sinkronisasi dibatalkan: Perangkat offline.');
      return;
    }

    final queue = await getQueue();
    if (queue.isEmpty) {
      return;
    }

    _isSyncing = true;
    if (onSyncStart != null) onSyncStart();

    debugPrint('Memulai sinkronisasi offline (${queue.length} item)...');

    for (final item in List.from(queue)) {
      bool success = false;
      try {
        final File file = File(item.localImagePath);
        if (!await file.exists()) {
          // File gambar hilang, hapus dari antrean agar tidak stuck
          debugPrint('File bukti tidak ditemukan di: ${item.localImagePath}, menghapus antrean.');
          await removeFromQueue(item.complaintId);
          continue;
        }

        // 1. Upload ke Firebase Storage
        final String fileName = p.basename(file.path);
        final ref = FirebaseStorage.instance
            .ref()
            .child('complaints/evidence/${item.complaintId}/$fileName');
        
        await ref.putFile(file);
        final String downloadUrl = await ref.getDownloadURL();

        // 2. Update status pengaduan di Firestore
        await FirebaseFirestore.instance
            .collection('complaints')
            .doc(item.complaintId)
            .update({
          'status': 'Selesai',
          'resolvedAt': Timestamp.fromDate(item.resolvedAt),
          'evidenceImageUrl': downloadUrl,
        });

        // 3. Sukses, bersihkan dari antrean lokal
        await removeFromQueue(item.complaintId);
        success = true;
        debugPrint('Sinkronisasi berhasil untuk pengaduan: ${item.complaintId}');
      } catch (e) {
        debugPrint('Gagal mensinkronisasikan pengaduan ${item.complaintId}: $e');
      }

      if (onItemSynced != null) {
        onItemSynced(item.complaintId, success);
      }
    }

    _isSyncing = false;
    if (onSyncComplete != null) onSyncComplete();
  }

  // ==========================================
  // BAGIAN 2: ANTREAN BUAT LAPORAN BARU (MASYARAKAT)
  // ==========================================

  /// Membaca seluruh antrean pembuatan pengaduan offline
  static Future<List<OfflineComplaintItem>> getComplaintQueue() async {
    try {
      final file = await _getComplaintsQueueFile();
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList.map((item) => OfflineComplaintItem.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Gagal membaca antrean laporan offline: $e');
      return [];
    }
  }

  /// Menyimpan antrean laporan baru ke file lokal
  static Future<void> _saveComplaintQueue(List<OfflineComplaintItem> queue) async {
    try {
      final file = await _getComplaintsQueueFile();
      final contents = json.encode(queue.map((item) => item.toMap()).toList());
      await file.writeAsString(contents);
    } catch (e) {
      debugPrint('Gagal menyimpan antrean laporan offline: $e');
    }
  }

  /// Menyimpan laporan baru secara offline
  static Future<void> addToComplaintQueue({
    required String id,
    required String userId,
    required String title,
    required String description,
    required String category,
    required File imageFile,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      // 1. Salin gambar ke lokasi dokumen lokal agar tidak hilang
      final directory = await getApplicationDocumentsDirectory();
      final String extension = p.extension(imageFile.path);
      final String newFileName = 'complaint_create_$id$extension';
      final String newPath = p.join(directory.path, newFileName);
      
      final File savedImage = await imageFile.copy(newPath);

      // 2. Baca antrean dan hapus duplikat jika ada
      final queue = await getComplaintQueue();
      queue.removeWhere((item) => item.id == id);

      // Tambahkan item baru
      queue.add(OfflineComplaintItem(
        id: id,
        userId: userId,
        title: title,
        description: description,
        category: category,
        localImagePath: savedImage.path,
        latitude: latitude,
        longitude: longitude,
        address: address,
        createdAt: DateTime.now(),
      ));

      // 3. Simpan antrean terbaru
      await _saveComplaintQueue(queue);
      debugPrint('Laporan pengaduan baru offline $id berhasil masuk antrean.');
    } catch (e) {
      debugPrint('Gagal menyimpan laporan baru offline: $e');
      rethrow;
    }
  }

  /// Menghapus laporan dari antrean pembuatan offline
  static Future<void> removeFromComplaintQueue(String id) async {
    try {
      final queue = await getComplaintQueue();
      final index = queue.indexWhere((item) => item.id == id);
      
      if (index != -1) {
        final item = queue[index];
        final file = File(item.localImagePath);
        if (await file.exists()) {
          await file.delete();
        }
        
        queue.removeAt(index);
        await _saveComplaintQueue(queue);
      }
    } catch (e) {
      debugPrint('Gagal menghapus antrean laporan offline $id: $e');
    }
  }

  /// Sinkronisasi antrean pembuatan pengaduan offline ke Firebase
  static Future<void> syncComplaintQueue({
    VoidCallback? onSyncStart,
    Function(String id, bool success)? onItemSynced,
    VoidCallback? onSyncComplete,
  }) async {
    if (_isSyncingComplaints) return;

    final isOnline = await hasInternetConnection();
    if (!isOnline) {
      debugPrint('Sinkronisasi pengaduan dibatalkan: Perangkat offline.');
      return;
    }

    final queue = await getComplaintQueue();
    if (queue.isEmpty) return;

    _isSyncingComplaints = true;
    if (onSyncStart != null) onSyncStart();

    debugPrint('Memulai sinkronisasi laporan offline baru (${queue.length} item)...');

    for (final item in List.from(queue)) {
      bool success = false;
      try {
        final File file = File(item.localImagePath);
        if (!await file.exists()) {
          debugPrint('File gambar laporan offline tidak ditemukan: ${item.localImagePath}');
          await removeFromComplaintQueue(item.id);
          continue;
        }

        // 1. Upload foto ke Firebase Storage
        final String fileName = p.basename(file.path);
        final ref = FirebaseStorage.instance
            .ref()
            .child('complaints/images/${item.userId}/${item.id}_$fileName');
        
        await ref.putFile(file);
        final String downloadUrl = await ref.getDownloadURL();

        // 2. Simpan data laporan ke Firestore
        await FirebaseFirestore.instance
            .collection('complaints')
            .doc(item.id)
            .set({
          'userId': item.userId,
          'title': item.title,
          'description': item.description,
          'imageUrl': downloadUrl,
          'latitude': item.latitude,
          'longitude': item.longitude,
          'address': item.address,
          'category': item.category,
          'status': 'Pending',
          'createdAt': Timestamp.fromDate(item.createdAt),
        });

        // 3. Bersihkan antrean lokal
        await removeFromComplaintQueue(item.id);
        success = true;
        debugPrint('Laporan pengaduan offline ${item.id} berhasil disinkronkan ke server.');
      } catch (e) {
        debugPrint('Gagal mensinkronisasikan laporan offline ${item.id}: $e');
      }

      if (onItemSynced != null) {
        onItemSynced(item.id, success);
      }
    }

    _isSyncingComplaints = false;
    if (onSyncComplete != null) onSyncComplete();
  }

  // ==========================================
  // BAGIAN KHUSUS KONEKTIVITAS
  // ==========================================

  /// Mengecek apakah koneksi internet aktif dengan mencoba mengontak host tepercaya
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
