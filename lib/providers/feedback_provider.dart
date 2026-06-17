import 'package:flutter/material.dart';
import '../models/feedback_model.dart';
import '../repositories/feedback_repository.dart';
import '../services/firestore_service.dart';

class FeedbackProvider extends ChangeNotifier {
  final FeedbackRepository _feedbackRepository = FeedbackRepository(
    FirestoreService(),
  );

  FeedbackModel? _currentFeedback;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  FeedbackModel? get currentFeedback => _currentFeedback;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Mengirim ulasan baru ke Firestore
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

  // Mengambil ulasan berdasarkan ID pengaduan
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

  // Membersihkan status ulasan saat ini
  void clearFeedback() {
    _currentFeedback = null;
    _errorMessage = null;
    notifyListeners();
  }
}
