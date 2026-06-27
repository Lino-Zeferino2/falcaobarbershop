import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String role; // 'cliente', 'barbeiro', 'admin'
  final DateTime createdAt;
  final double points; // Pontos acumulados para desconto
  final String? barbeariaId; // ID da barbearia associada (para barbeiros)
  final List<String> fcmTokens; // FCM tokens for push notifications

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.role,
    required this.createdAt,
    this.points = 0.0,
    this.barbeariaId,
    this.fcmTokens = const [],
  });

  // Converter para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'points': points,
      'barbeariaId': barbeariaId,
      'fcmTokens': fcmTokens,
    };
  }

  // Criar UserModel a partir de Map (do Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      city: map['city'] ?? '',
      role: map['role'] ?? 'cliente',
      createdAt: map['createdAt'] is Timestamp ? (map['createdAt'] as Timestamp).toDate() : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      points: (map['points'] ?? 0.0).toDouble(),
      barbeariaId: map['barbeariaId'],
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
    );
  }

  // Criar cópia com alterações
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? city,
    String? role,
    DateTime? createdAt,
    double? points,
    String? barbeariaId,
    List<String>? fcmTokens,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      points: points ?? this.points,
      barbeariaId: barbeariaId ?? this.barbeariaId,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }
}
