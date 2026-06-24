import '../models/feedback_model.dart';
import '../services/firestore_service.dart';

/// Repositori [FeedbackRepository] menangani pengiriman dan pengambilan data umpan balik 
/// atau ulasan kepuasan ([FeedbackModel]) dari para pengguna terkait penyelesaian laporan pengaduan sampah.
class FeedbackRepository {
  /// Sumber data penyimpanan Firestore.
  final FirestoreService _firestoreService;

  /// Membuat konstruktor [FeedbackRepository] dengan ketergantungan pada [FirestoreService].
  /// Menerima parameter [_firestoreService] sebagai penyedia layanan Firestore.
  FeedbackRepository(this._firestoreService);

  /// Menyimpan ulasan umpan balik ([feedback]) baru ke Firestore pada koleksi `feedback/`
  /// dengan ID dokumen sesuai dengan ID umpan balik tersebut.
  Future<void> submitFeedback(FeedbackModel feedback) async {
    await _firestoreService.setData(
      path: 'feedback/${feedback.id}',
      data: feedback.toMap(),
    );
  }

  /// Mengambil data umpan balik ([FeedbackModel]) untuk laporan pengaduan tertentu berdasarkan [complaintId].
  /// Mengembalikan objek [FeedbackModel], atau `null` jika pengaduan tersebut belum memiliki ulasan kepuasan.
  Future<FeedbackModel?> fetchFeedbackForComplaint(String complaintId) async {
    final doc = await _firestoreService.getDocument(path: 'feedback/$complaintId');
    if (doc.exists && doc.data() != null) {
      return FeedbackModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}

