import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DateFormatter {
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
