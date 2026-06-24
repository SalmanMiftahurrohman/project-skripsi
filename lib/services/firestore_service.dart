import 'package:cloud_firestore/cloud_firestore.dart';

/// Layanan [FirestoreService] menyediakan wrapper generik untuk melakukan operasi CRUD 
/// (Create, Read, Update, Delete) ke database Cloud Firestore.
class FirestoreService {
  /// Instance [FirebaseFirestore] untuk melakukan query database.
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Menulis atau memperbarui data dokumen pada path tertentu ([path]).
  /// 
  /// Menerima parameter [data] berupa Map, dan flag [merge]. Jika [merge] bernilai `true`,
  /// hanya field yang baru yang akan diupdate tanpa menghapus field lama dalam dokumen.
  Future<void> setData({required String path, required Map<String, dynamic> data, bool merge = true}) async {
    final docRef = _db.doc(path);
    await docRef.set(data, SetOptions(merge: merge));
  }

  /// Menghapus dokumen dari database Firestore berdasarkan path ([path]) yang diberikan.
  Future<void> deleteData({required String path}) async {
    final docRef = _db.doc(path);
    await docRef.delete();
  }

  /// Memperbarui sebagian field dari dokumen tertentu pada path ([path]) dengan data baru ([data]).
  /// Operasi ini akan error jika dokumen target belum ada sebelumnya di database.
  Future<void> updateData({required String path, required Map<String, dynamic> data}) async {
    final docRef = _db.doc(path);
    await docRef.update(data);
  }

  /// Mengambil data dokumen tunggal (snapshot) dari database Firestore berdasarkan [path] yang diberikan.
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({required String path}) async {
    return await _db.doc(path).get();
  }

  /// Mengambil data real-time stream dari suatu koleksi dokumen berdasarkan path ([path]).
  /// 
  /// Menerima parameter opsional [queryBuilder] untuk menyaring (filter), mengurutkan (sort), 
  /// atau membatasi (limit) hasil data koleksi.
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
