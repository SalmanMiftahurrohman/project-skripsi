import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Layanan [StorageService] menangani operasi pengunggahan (upload) dan penghapusan (delete) 
/// file media (seperti foto penumpukan sampah atau foto profil) ke Firebase Storage.
class StorageService {
  /// Instance [FirebaseStorage] untuk berinteraksi dengan bucket penyimpanan awan.
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Mengunggah file lokal ([file]) ke Firebase Storage pada path tujuan tertentu ([path]).
  /// 
  /// Setelah unggahan selesai, fungsi ini mengambil dan mengembalikan alamat URL publik ([String]) 
  /// yang mengarah ke file tersebut agar dapat disimpan dalam dokumen Firestore.
  Future<String> uploadFile({
    required String path,
    required File file,
  }) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  /// Menghapus file yang ada di Firebase Storage menggunakan referensi tautan URL ([url]) file tersebut.
  Future<void> deleteFile({required String url}) async {
    final ref = _storage.refFromURL(url);
    await ref.delete();
  }
}
