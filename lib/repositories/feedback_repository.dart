import '../models/feedback_model.dart';
import '../services/firestore_service.dart';

class FeedbackRepository {
  final FirestoreService _firestoreService;

  FeedbackRepository(this._firestoreService);


  Future<void> submitFeedback(FeedbackModel feedback) async {
    await _firestoreService.setData(
      path: 'feedback/${feedback.id}',
      data: feedback.toMap(),
    );
  }

  Future<FeedbackModel?> fetchFeedbackForComplaint(String complaintId) async {
    final doc = await _firestoreService.getDocument(path: 'feedback/$complaintId');
    if (doc.exists && doc.data() != null) {
      return FeedbackModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}

