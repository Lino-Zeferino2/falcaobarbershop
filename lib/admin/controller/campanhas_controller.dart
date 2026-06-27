import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../firestore_instance.dart';

class CampanhaModel {
  final String id;
  final String titulo;
  final String descricao;
  final DateTime? createdAt;

  const CampanhaModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.createdAt,
  });

  factory CampanhaModel.fromMap(Map<String, dynamic> data, String id) {
    final createdAtValue = data['createdAt'];
    DateTime? createdAt;

    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is String) {
      try {
        createdAt = DateTime.parse(createdAtValue);
      } catch (_) {
        createdAt = null;
      }
    }

    return CampanhaModel(
      id: id,
      titulo: (data['titulo'] ?? '') as String,
      descricao: (data['descricao'] ?? '') as String,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descricao': descricao,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

class CampanhaEnvioModel {
  final String id;
  final String clienteId;
  final String campanhaId;
  final DateTime? sentAt;
  final String? canal;

  const CampanhaEnvioModel({
    required this.id,
    required this.clienteId,
    required this.campanhaId,
    required this.sentAt,
    required this.canal,
  });

  factory CampanhaEnvioModel.fromMap(Map<String, dynamic> data, String id) {
    final sentAtValue = data['sentAt'];
    DateTime? sentAt;

    if (sentAtValue is Timestamp) {
      sentAt = sentAtValue.toDate();
    } else if (sentAtValue is String) {
      try {
        sentAt = DateTime.parse(sentAtValue);
      } catch (_) {
        sentAt = null;
      }
    }

    return CampanhaEnvioModel(
      id: id,
      clienteId: (data['clienteId'] ?? '') as String,
      campanhaId: (data['campanhaId'] ?? '') as String,
      sentAt: sentAt,
      canal: data['canal'] as String?,
    );
  }
}

class CampanhasController {
  final FirebaseFirestore _firestore = firestore;

  Future<void> criarCampanha({
    required String titulo,
    required String descricao,
  }) async {
    await _firestore.collection('campanhas').add({
      'titulo': titulo,
      'descricao': descricao,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sem orderBy para evitar problemas se o campo `createdAt` não existir
  /// ou vier com tipo diferente.
  Stream<List<CampanhaModel>> streamAllCampanhas() {
    return _firestore
        .collection('campanhas')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => CampanhaModel.fromMap(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  Future<void> updateCampanha({
    required String id,
    required String titulo,
    required String descricao,
  }) async {
    await _firestore.collection('campanhas').doc(id).update({
      'titulo': titulo,
      'descricao': descricao,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCampanha(String id) async {
    await _firestore.collection('campanhas').doc(id).delete();
  }

  /// Persiste o envio/registro de campanha para contagem por cliente.
  Future<void> logEnvioCampanha({
    required String clienteId,
    required String campanhaId,
    String? canal,
  }) async {
    await _firestore.collection('campanha_envios').add({
      'clienteId': clienteId,
      'campanhaId': campanhaId,
      'canal': canal,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> getEnvioStatsPorCliente(String clienteId) async {
    try {
      final query = await _firestore
          .collection('campanha_envios')
          .where('clienteId', isEqualTo: clienteId)
          .get();

      DateTime? ultimoAt;
      String? ultimaCampanhaId;

      // encontra o último envio (e a campanha do último envio)
      for (final doc in query.docs) {
        final data = doc.data();
        final sentAtValue = data['sentAt'];
        DateTime? sentAt;

        if (sentAtValue is Timestamp) {
          sentAt = sentAtValue.toDate();
        } else if (sentAtValue is String) {
          try {
            sentAt = DateTime.parse(sentAtValue);
          } catch (_) {
            sentAt = null;
          }
        }

        final campanhaId = (data['campanhaId'] ?? '') as String;

        if (sentAt != null && (ultimoAt == null || sentAt.isAfter(ultimoAt))) {
          ultimoAt = sentAt;
          ultimaCampanhaId = campanhaId;
        }
      }

      // escopo 2: qtd por cliente + mesma campanha do último envio
      if (ultimaCampanhaId == null || ultimoAt == null) {
        return {
          'qtdEnvios': 0,
          'ultimoEnvioAt': null,
        };
      }

      final qtdParaUltimaCampanha = query.docs.where((doc) {
        final data = doc.data();
        final campanhaId = (data['campanhaId'] ?? '') as String;
        return campanhaId == ultimaCampanhaId;
      }).length;

      return {
        'qtdEnvios': qtdParaUltimaCampanha,
        'ultimoEnvioAt': ultimoAt,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getEnvioStatsPorCliente: $e');
      }
      return {
        'qtdEnvios': 0,
        'ultimoEnvioAt': null,
      };
    }
  }
}
