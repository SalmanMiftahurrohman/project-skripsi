import 'package:flutter/material.dart';
import '../models/feedback_model.dart';
import '../repositories/feedback_repository.dart';
import '../services/firestore_service.dart';

/// Penyedia state [FeedbackProvider] mengelola status umpan balik (rating & komentar) kepuasan.
/// 
/// Ini memfasilitasi pengiriman ulasan kepuasan dari masyarakat dan pengambilan data ulasan
/// untuk ditampilkan pada detil laporan pengaduan yang sudah diselesaikan.
class FeedbackProvider extends ChangeNotifier {
  /// Instansiasi [FeedbackRepository] untuk menangani data umpan balik.
  final FeedbackRepository _feedbackRepository = FeedbackRepository(
    FirestoreService(),
  );

  /// Umpan balik yang dimuat saat ini.
  FeedbackModel? _currentFeedback;

  /// Menunjukkan status loading proses pengiriman/pengambilan data.
  bool _isLoading = false;

  /// Pesan error/kesalahan jika terjadi kegagalan transaksi data.
  String? _errorMessage;

  /// Mendapatkan data ulasan umpan balik aktif saat ini.
  FeedbackModel? get currentFeedback => _currentFeedback;

  /// Mendapatkan status loading aktif.
  bool get isLoading => _isLoading;

  /// Mendapatkan pesan error/kesalahan terakhir.
  String? get errorMessage => _errorMessage;

  /// Mengirim ulasan umpan balik baru dari pengguna ke Firestore.
  /// 
  /// Menerima parameter [complaintId] pengaduan terkait, [userId] pengirim,
  /// nilai tingkat kepuasan [rating] (1-5), dan isi saran/komentar [comment].
  /// Mengembalikan `true` jika pengiriman ulasan berhasil.
  Future<bool> submitFeedback({
    required String complaintId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final feedback = FeedbackModel(
        id: complaintId, // ID ulasan disamakan dengan complaintId
        complaintId: complaintId,
        userId: userId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      await _feedbackRepository.submitFeedback(feedback);
      _currentFeedback = feedback;
      
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

  /// Mengambil data ulasan kepuasan ([FeedbackModel]) terkait [complaintId] tertentu dari database.
  Future<FeedbackModel?> fetchFeedbackForComplaint(String complaintId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final feedback = await _feedbackRepository.fetchFeedbackForComplaint(complaintId);
      _currentFeedback = feedback;
      _isLoading = false;
      notifyListeners();
      return feedback;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Membersihkan data umpan balik aktif di dalam cache lokal state.
  void clearFeedback() {
    _currentFeedback = null;
    _errorMessage = null;
    notifyListeners();
  }
}
