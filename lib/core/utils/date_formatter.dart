import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Kelas [DateFormatter] menyediakan utilitas untuk memformat objek [Timestamp] 
/// dari Firestore menjadi representasi teks tanggal dan waktu yang mudah dibaca oleh pengguna.
class DateFormatter {
  /// Memformat [Timestamp] menjadi format tanggal dan waktu lengkap berbahasa Indonesia.
  /// 
  /// Format output: `dd MMMM yyyy, HH:mm` (Contoh: `24 Juni 2026, 22:30`).
  /// Jika terjadi kegagalan/locale 'id_ID' belum diinisialisasi, akan menggunakan format fallback `dd/MM/yyyy HH:mm`.
  /// Mengembalikan `-` jika nilai [timestamp] bernilai null.
  static String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    
    DateTime dateTime = timestamp.toDate();
    // Gunakan formatting bahasa Indonesia (lokal)
    try {
      final DateFormat formatter = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');
      return formatter.format(dateTime);
    } catch (e) {
      // Fallback jika locale id_ID tidak diinisialisasi
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }

  /// Memformat [Timestamp] menjadi format tanggal pendek berbahasa Indonesia tanpa informasi waktu.
  /// 
  /// Format output: `dd MMM yyyy` (Contoh: `24 Jun 2026`).
  /// Jika terjadi kegagalan/locale 'id_ID' belum diinisialisasi, akan menggunakan format fallback `dd/MM/yyyy`.
  /// Mengembalikan `-` jika nilai [timestamp] bernilai null.
  static String formatShortDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    
    DateTime dateTime = timestamp.toDate();
    try {
      final DateFormat formatter = DateFormat('dd MMM yyyy', 'id_ID');
      return formatter.format(dateTime);
    } catch (e) {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }
}
