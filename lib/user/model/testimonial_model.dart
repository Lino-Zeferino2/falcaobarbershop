import 'package:cloud_firestore/cloud_firestore.dart';

class TestimonialModel {
  final String id;
  final String userId;
  final String? userName;
  final String description;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isAnonymous;

  TestimonialModel({
    required this.id,
    required this.userId,
    required this.description,
    this.userName,
    this.imageUrl,
    required this.createdAt,
    this.isAnonymous = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'isAnonymous': isAnonymous,
    };
  }

  factory TestimonialModel.fromMap(Map<String, dynamic> map) {
    return TestimonialModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'],
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      isAnonymous: map['isAnonymous'] ?? false,
    );
  }
}
