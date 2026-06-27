import 'package:cloud_firestore/cloud_firestore.dart';

class VipSubscriptionModel {
  final String id;
  final String userId;
  final String planoId;
  final String planoNome;
  final double valorMensal;
  final String status; // "pendente_pagamento", "ativo", "cancelado", "expirado"
  final DateTime dataSubscricao;
  final DateTime? dataAtivacao;
  final DateTime? dataRenovacao;

  VipSubscriptionModel({
    required this.id,
    required this.userId,
    required this.planoId,
    required this.planoNome,
    required this.valorMensal,
    required this.status,
    required this.dataSubscricao,
    this.dataAtivacao,
    this.dataRenovacao,
  });

  factory VipSubscriptionModel.fromMap(String id, Map<String, dynamic> data) {
    return VipSubscriptionModel(
      id: id,
      userId: data['userId'] ?? '',
      planoId: data['planoId'] ?? '',
      planoNome: data['planoNome'] ?? '',
      valorMensal: (data['valorMensal'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pendente_pagamento',
      dataSubscricao: (data['dataSubscricao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataAtivacao: (data['dataAtivacao'] as Timestamp?)?.toDate(),
      dataRenovacao: (data['dataRenovacao'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'planoId': planoId,
      'planoNome': planoNome,
      'valorMensal': valorMensal,
      'status': status,
      'dataSubscricao': FieldValue.serverTimestamp(),
      'dataAtivacao': dataAtivacao != null ? Timestamp.fromDate(dataAtivacao!) : null,
      'dataRenovacao': dataRenovacao != null ? Timestamp.fromDate(dataRenovacao!) : null,
    };
  }
}
