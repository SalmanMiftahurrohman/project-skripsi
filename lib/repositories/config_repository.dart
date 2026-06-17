import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class ConfigRepository {
  final FirestoreService _firestoreService;

  ConfigRepository(this._firestoreService);


  Future<String?> getOfficerCode() async {
    final snap = await _firestoreService.getDocument(path: 'config/officer_code');
    if (snap.exists && snap.data() != null) {
      return snap.data()!['code'] as String?;
    }
    return null;
  }

  Future<void> updateOfficerCode(String newCode) async {
    await _firestoreService.setData(
      path: 'config/officer_code',
      data: {
        'code': newCode,
        'updatedAt': Timestamp.now(),
      },
    );
  }
}

