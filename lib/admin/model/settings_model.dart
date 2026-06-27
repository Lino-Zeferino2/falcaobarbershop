import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsModel {
  final String id;
  final String barbeariaNome;
  final String email;
  final String instagram;
  final String horarioFuncionamento;
  final String descricaoCurta;
  final String subDescricao;
  final String whatsApp;
  final List<String> diasAtendimento;
  final Map<String, Map<String, String>> turnos; // {"manha": {"inicio": "09:00", "fim": "12:00"}, "tarde": {"inicio": "14:00", "fim": "18:00"}}
  final DateTime createdAt;
  final DateTime updatedAt;

  SettingsModel({
    required this.id,
    required this.barbeariaNome,
    required this.email,
    required this.instagram,
    required this.horarioFuncionamento,
    required this.descricaoCurta,
    required this.subDescricao,
    required this.whatsApp,
    required this.diasAtendimento,
    required this.turnos,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SettingsModel.fromMap(String id, Map<String, dynamic> map) {
    return SettingsModel(
      id: id,
      barbeariaNome: map['barbeariaNome'] ?? '',
      email: map['email'] ?? '',
      instagram: map['instagram'] ?? '',
      horarioFuncionamento: map['horarioFuncionamento'] ?? '',
      descricaoCurta: map['descricaoCurta'] ?? '',
      subDescricao: map['subDescricao'] ?? '',
      whatsApp: map['whatsApp'] ?? '',
      diasAtendimento: List<String>.from(map['diasAtendimento'] ?? []),
      turnos: (map['turnos'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, Map<String, String>.from(value as Map)),
      ) ?? {},
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barbeariaNome': barbeariaNome,
      'email': email,
      'instagram': instagram,
      'horarioFuncionamento': horarioFuncionamento,
      'descricaoCurta': descricaoCurta,
      'subDescricao': subDescricao,
      'whatsApp': whatsApp,
      'diasAtendimento': diasAtendimento,
      'turnos': turnos,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  SettingsModel copyWith({
    String? id,
    String? barbeariaNome,
    String? email,
    String? instagram,
    String? horarioFuncionamento,
    String? descricaoCurta,
    String? subDescricao,
    String? whatsApp,
    List<String>? diasAtendimento,
    Map<String, Map<String, String>>? turnos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      barbeariaNome: barbeariaNome ?? this.barbeariaNome,
      email: email ?? this.email,
      instagram: instagram ?? this.instagram,
      horarioFuncionamento: horarioFuncionamento ?? this.horarioFuncionamento,
      descricaoCurta: descricaoCurta ?? this.descricaoCurta,
      subDescricao: subDescricao ?? this.subDescricao,
      whatsApp: whatsApp ?? this.whatsApp,
      diasAtendimento: diasAtendimento ?? this.diasAtendimento,
      turnos: turnos ?? this.turnos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
