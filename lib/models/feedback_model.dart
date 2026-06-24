import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data [FeedbackModel] merepresentasikan umpan balik/ulasan kepuasan
/// yang diberikan oleh masyarakat setelah laporan pengaduan sampah mereka dinyatakan 'Selesai'.
class FeedbackModel {
  /// ID unik dokumen umpan balik di Firestore.
  final String id;

  /// ID pengaduan ([ComplaintModel.id]) terkait dengan umpan balik ini.
  final String complaintId;

  /// ID pengguna (Masyarakat) yang memberikan umpan balik.
  final String userId;

  /// Nilai kepuasan dari 1 sampai 5 bintang (1 = sangat tidak puas, 5 = sangat puas).
  final int rating;

  /// Catatan, saran, atau komentar tambahan dari pengguna mengenai penanganan sampah.
  final String comment;

  /// Waktu ketika umpan balik ini dikirimkan.
  final DateTime createdAt;

  /// Membuat instance baru dari [FeedbackModel].
  FeedbackModel({
    required this.id,
    required this.complaintId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  /// Mengonversi map mentah dari Firestore ([map]) dan [id] dokumen menjadi objek [FeedbackModel].
  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      complaintId: map['complaintId'] ?? '',
      userId: map['userId'] ?? '',
      rating: map['rating'] ?? 5,
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Mengonversi objek [FeedbackModel] menjadi format [Map] untuk disimpan di Firestore.
  Map<String, dynamic> toMap() {
    return {
      'complaintId': complaintId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
