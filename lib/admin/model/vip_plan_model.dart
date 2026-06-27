import 'package:cloud_firestore/cloud_firestore.dart';

class VipPlanModel {
  final String id;
  final String name;
  final double price;
  final String description;
  final List<String> benefits;
  final bool isActive;
  final DateTime createdAt;
  final int subscribersCount; // This will be calculated dynamically

  VipPlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.benefits,
    required this.isActive,
    required this.createdAt,
    this.subscribersCount = 0,
  });

  factory VipPlanModel.fromMap(String id, Map<String, dynamic> data) {
    return VipPlanModel(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      benefits: List<String>.from(data['benefits'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subscribersCount: data['subscribersCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'benefits': benefits,
      'isActive': isActive,
      'createdAt': createdAt,
      'subscribersCount': subscribersCount,
    };
  }

  VipPlanModel copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    List<String>? benefits,
    bool? isActive,
    DateTime? createdAt,
    int? subscribersCount,
  }) {
    return VipPlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      benefits: benefits ?? this.benefits,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      subscribersCount: subscribersCount ?? this.subscribersCount,
    );
  }
}
