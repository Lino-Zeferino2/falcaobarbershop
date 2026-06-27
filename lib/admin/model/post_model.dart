import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String description;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostModel({
    required this.id,
    required this.description,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Converter para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Criar PostModel a partir de Map (do Firestore)
  factory PostModel.fromMap(Map<String, dynamic> map) {
    try {
      print('DEBUG PostModel.fromMap: map = $map');
      final createdAt = (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] as String);
      final updatedAt = (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] as String);
      return PostModel(
        id: map['id'] as String,
        description: map['description'] as String,
        imageUrl: map['imageUrl'] as String?,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      print('ERROR PostModel.fromMap: Erro ao parsear datas: $e');
      print('ERROR PostModel.fromMap: map = $map');
      // Fallback
      return PostModel(
        id: map['id'] as String? ?? '',
        description: map['description'] as String? ?? '',
        imageUrl: map['imageUrl'] as String?,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Criar cópia com alterações
  PostModel copyWith({
    String? id,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
