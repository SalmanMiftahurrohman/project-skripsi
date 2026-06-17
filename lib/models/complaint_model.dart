import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String address;
  final String category; // 'Kebersihan', dll
  final String status; // 'Pending', 'Diterima', 'Terverifikasi', 'Diproses', 'Selesai'
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? resolvedAt;
  final String? evidenceImageUrl; // Bukti dari petugas
  final String? rejectionReason; // Alasan penolakan dari petugas

  ComplaintModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.category,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.resolvedAt,
    this.evidenceImageUrl,
    this.rejectionReason,
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String id) {
    return ComplaintModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] ?? '',
      category: map['category'] ?? 'Kebersihan',
      status: map['status'] ?? 'Pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (map['processedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      evidenceImageUrl: map['evidenceImageUrl'],
      rejectionReason: map['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'category': category,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'evidenceImageUrl': evidenceImageUrl,
      'rejectionReason': rejectionReason,
    };
  }
}
