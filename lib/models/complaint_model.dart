import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data [ComplaintModel] merepresentasikan laporan pengaduan sampah 
/// yang dibuat oleh masyarakat dan dikelola oleh petugas/admin.
class ComplaintModel {
  /// ID unik laporan pengaduan di Firestore.
  final String id;

  /// ID pengguna (Masyarakat) yang mengajukan laporan.
  final String userId;

  /// Judul singkat laporan pengaduan sampah.
  final String title;

  /// Deskripsi detail terkait penumpukan sampah (contoh: jenis sampah, estimasi volume).
  final String description;

  /// URL foto lokasi penumpukan sampah yang diunggah pelapor.
  final String imageUrl;

  /// Koordinat garis lintang (latitude) lokasi penumpukan sampah.
  final double latitude;

  /// Koordinat garis bujur (longitude) lokasi penumpukan sampah.
  final double longitude;

  /// Alamat lengkap atau petunjuk lokasi penumpukan sampah.
  final String address;

  /// Kategori sampah (contoh: 'Kebersihan', 'Limbah B3', dll.).
  final String category;

  /// Status penanganan laporan saat ini.
  /// 
  /// Nilai yang valid: 'Pending', 'Diterima', 'Terverifikasi', 'Diproses', 'Selesai'.
  final String status;

  /// Waktu pembuatan laporan pengaduan.
  final DateTime createdAt;

  /// Waktu ketika laporan mulai diproses oleh petugas.
  final DateTime? processedAt;

  /// Waktu ketika laporan berhasil diselesaikan.
  final DateTime? resolvedAt;

  /// URL foto bukti penyelesaian yang diunggah oleh petugas setelah membersihkan sampah.
  final String? evidenceImageUrl;

  /// Alasan penolakan laporan jika statusnya ditolak/ditangguhkan oleh petugas/admin.
  final String? rejectionReason;

  /// Membuat instance baru dari [ComplaintModel].
  ComplaintModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.category,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.resolvedAt,
    this.evidenceImageUrl,
    this.rejectionReason,
  });

  /// Mengonversi map mentah dari Firestore ([map]) dan [id] dokumen menjadi objek [ComplaintModel].
  factory ComplaintModel.fromMap(Map<String, dynamic> map, String id) {
    return ComplaintModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] ?? '',
      category: map['category'] ?? 'Kebersihan',
      status: map['status'] ?? 'Pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (map['processedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      evidenceImageUrl: map['evidenceImageUrl'],
      rejectionReason: map['rejectionReason'],
    );
  }

  /// Mengonversi objek [ComplaintModel] menjadi format [Map] untuk disimpan di Firestore.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'category': category,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'evidenceImageUrl': evidenceImageUrl,
      'rejectionReason': rejectionReason,
    };
  }
}
