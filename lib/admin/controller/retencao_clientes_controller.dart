import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../firestore_instance.dart';
import '../../user/model/user_model.dart';
import '../controller/admin_controller.dart';
import 'campanhas_controller.dart';

class RetencaoClientesItem {
  final String clienteId;
  final String nome;
  final String email;
  final String telemovel;
  final int totalAgendamentos;
  final double totalGasto;
  final DateTime? ultimoAgendamento;

  /// Quantidade de envios de campanhas para este cliente
  final int qtdEnviosCampanha;

  /// Data do último envio
  final DateTime? ultimoEnvioAt;

  const RetencaoClientesItem({
    required this.clienteId,
    required this.nome,
    required this.email,
    required this.telemovel,
    required this.totalAgendamentos,
    required this.totalGasto,
    required this.ultimoAgendamento,
    required this.qtdEnviosCampanha,
    required this.ultimoEnvioAt,
  });
}

class RetencaoClientesController {
  final FirebaseFirestore _firestore = firestore;
  final AdminController _adminController = AdminController();
  final CampanhasController _campanhasController = CampanhasController();

  /// Total geral (clientes do role=cliente) para exibir "X de Y".
  Future<int> getTotalClientesCount() async {
    final snapshot = await _firestore
        .collection('clientes')
        .where('role', isEqualTo: 'cliente')
        .get();
    return snapshot.docs.length;
  }

 Future<List<RetencaoClientesItem>> getRetencaoClientes({
  required int minMonthsSinceLastAppointment,
}) async {
  final clientesSnapshot = await _firestore
      .collection('clientes')
      .where('role', isEqualTo: 'cliente')
      .get();

  final clientes = clientesSnapshot.docs
      .map((d) => UserModel.fromMap(d.data()))
      .toList();

  if (clientes.isEmpty) return [];

  final clienteIds = clientes.map((c) => c.uid).toList();

  // 1 pedido em lote (por grupos de 10, limite do whereIn) para TODOS os
  // agendamentos de TODOS os clientes de uma vez, em vez de 3 queries
  // separadas por cliente (último agendamento, contagem, total gasto).
  final Map<String, List<Map<String, dynamic>>> agendamentosPorCliente = {};
  const batchSize = 10;
  final batches = <Future<void>>[];

  for (var i = 0; i < clienteIds.length; i += batchSize) {
    final end = (i + batchSize < clienteIds.length) ? i + batchSize : clienteIds.length;
    final batchIds = clienteIds.sublist(i, end);

    batches.add(
      _firestore
          .collection('agendamentos')
          .where('userId', whereIn: batchIds)
          .get()
          .then((snap) {
        for (final doc in snap.docs) {
          final data = doc.data();
          final userId = data['userId'] as String?;
          if (userId == null) continue;
          agendamentosPorCliente.putIfAbsent(userId, () => []).add(data);
        }
      }).catchError((e) {
        if (kDebugMode) print('Error fetching agendamentos batch: $e');
      }),
    );
  }

  await Future.wait(batches);

  final items = <RetencaoClientesItem>[];
// Busca todos os stats de campanha de uma vez, em vez de 1 query por
// cliente dentro do loop abaixo.
final envioStatsPorCliente = await _campanhasController.getEnvioStatsPorClientes(clienteIds);
// Todas as fontes de dados (agendamentos e campanhas) já foram buscadas em
// lote acima — este loop é só processamento em memória.
  await Future.wait(clientes.map((cliente) async {
    final agendamentos = agendamentosPorCliente[cliente.uid] ?? [];

    // Último agendamento: maior data entre todos os agendamentos do cliente
    // (qualquer status), replicando o comportamento original.
    DateTime? lastApptDate;
    for (final data in agendamentos) {
      final dateStr = data['date'] as String?;
      if (dateStr == null) continue;
      try {
        final parsed = DateTime.parse(dateStr);
        if (lastApptDate == null || parsed.isAfter(lastApptDate)) {
          lastApptDate = parsed;
        }
      } catch (_) {}
    }

    final monthsSince = _adminController.getMonthsSinceLastAppointment(lastApptDate);
    if (monthsSince < minMonthsSinceLastAppointment) return;

    final totalAgendamentos = agendamentos.length;

    double totalGasto = 0.0;
    for (final data in agendamentos) {
      if (data['status'] != 'completed') continue;
      final priceValue = data['price'];
      if (priceValue is num) {
        totalGasto += priceValue.toDouble();
      } else if (priceValue is String) {
        totalGasto += double.tryParse(priceValue) ?? 0.0;
      }
    }

    final envioStats = envioStatsPorCliente[cliente.uid] ?? {'qtdEnvios': 0, 'ultimoEnvioAt': null};
    final qtdEnviosRaw = envioStats['qtdEnvios'];
    final qtdEnvios = qtdEnviosRaw is num ? qtdEnviosRaw.toInt() : 0;
    final ultimoEnvioRaw = envioStats['ultimoEnvioAt'];
    final ultimoEnvioAt = ultimoEnvioRaw is DateTime ? ultimoEnvioRaw : null;

    items.add(
      RetencaoClientesItem(
        clienteId: cliente.uid,
        nome: cliente.name,
        email: cliente.email,
        telemovel: cliente.phone,
        totalAgendamentos: totalAgendamentos,
        totalGasto: totalGasto,
        ultimoAgendamento: lastApptDate,
        qtdEnviosCampanha: qtdEnvios,
        ultimoEnvioAt: ultimoEnvioAt,
      ),
    );
  }));

  items.sort((a, b) {
    final aDate = a.ultimoAgendamento;
    final bDate = b.ultimoAgendamento;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return -1;
    if (bDate == null) return 1;
    return aDate.compareTo(bDate);
  });

  return items;
}


}
