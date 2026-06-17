import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String complaintId;
  final String userId;
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.complaintId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      complaintId: map['complaintId'] ?? '',
      userId: map['userId'] ?? '',
      rating: map['rating'] ?? 5,
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'complaintId': complaintId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
