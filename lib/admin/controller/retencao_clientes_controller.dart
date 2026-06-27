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

    final items = <RetencaoClientesItem>[];

    await Future.wait(clientes.map((cliente) async {
      final lastAppt = await _adminController.getClienteLastAppointment(cliente.uid);

      final monthsSince = _adminController.getMonthsSinceLastAppointment(lastAppt?.dateTime);

      // monthsSince == -1 when no appointment; for inactivity filters we don't include those by default
      if (monthsSince < minMonthsSinceLastAppointment) return;

      final totalAgendamentos = await _adminController.getClienteAppointmentsCount(cliente.uid);
      final totalGasto = await _calculateTotalGastoCompleted(cliente.uid);

      final envioStats = await _campanhasController.getEnvioStatsPorCliente(cliente.uid);

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
          ultimoAgendamento: lastAppt?.dateTime,
          qtdEnviosCampanha: qtdEnvios,
          ultimoEnvioAt: ultimoEnvioAt,
        ),
      );
    }));

    // Sort by "ultimoAgendamento mais antigo" (maior retenção)
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

  Future<double> _calculateTotalGastoCompleted(String clienteId) async {
    try {
      final query = await _firestore
          .collection('agendamentos')
          .where('userId', isEqualTo: clienteId)
          .where('status', isEqualTo: 'completed')
          .get();

      double total = 0.0;

      for (final doc in query.docs) {
        final data = doc.data();
        final priceValue = data['price'];

        if (priceValue is num) {
          total += priceValue.toDouble();
        } else if (priceValue is String) {
          total += double.tryParse(priceValue) ?? 0.0;
        }
      }

      return total;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating total gasto for clienteId=$clienteId: $e');
      }
      return 0.0;
    }
  }
}
