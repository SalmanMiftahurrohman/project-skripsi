import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Generic document read/write methods
  Future<void> setData({required String path, required Map<String, dynamic> data, bool merge = true}) async {
    final docRef = _db.doc(path);
    await docRef.set(data, SetOptions(merge: merge));
  }

  Future<void> deleteData({required String path}) async {
    final docRef = _db.doc(path);
    await docRef.delete();
  }

  Future<void> updateData({required String path, required Map<String, dynamic> data}) async {
    final docRef = _db.doc(path);
    await docRef.update(data);
  }


  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({required String path}) async {
    return await _db.doc(path).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> collectionStream({
    required String path,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }
}
