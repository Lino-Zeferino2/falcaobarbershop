import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../firestore_instance.dart';
import '../model/appointment_model.dart';
import '../model/barber_model.dart';
import '../model/barbearia_model.dart';
import '../model/notification_model.dart';
import '../model/profissional_model.dart';
import '../model/service_model.dart';
import '../model/vip_plan_model.dart';
import '../model/vip_subscription_model.dart';
import '../model/settings_model.dart';
import '../model/post_model.dart';
import '../../user/model/user_model.dart';
import '../../user/controller/auth_controller.dart';
import '../../services/email_service.dart';

class AdminController {
  final FirebaseFirestore _firestore = firestore; // (default)



  final StreamController<int> _unreadCountController = StreamController<int>.broadcast();
  final Map<String, String> _professionalNameCache = {};
  final Map<String, int> _serviceDurationCache = {};

  Stream<int> get unreadNotificationsCountStream => _unreadCountController.stream;

  String _getWeekdayName(int weekday) {
    const weekdays = ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'];
    return weekdays[weekday - 1];
  }

  // Obter estatísticas do dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = today.toString().substring(0, 10); // "2024-01-15"

      // Novos clientes (últimos 30 dias)
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final newClients = await _firestore
          .collection('clientes')
          .where('createdAt', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .get();

      // Clientes com contas criadas (role = 'cliente')
      final activeClients = await _firestore
          .collection('clientes')
          .where('role', isEqualTo: 'cliente')
          .get();

      // Todos os agendamentos (default)
      final allAppointmentsSnapshot = await _firestore.collection('agendamentos').get();


      int todayAppointmentsCount = 0;
      double estimatedRevenue = 0.0; // Receita estimada (hoje, confirmed OU completed)
      int totalCuts = 0;
      double totalRevenue = 0.0; // Receita total (completed desde sempre)
      Map<String, int> serviceCount = {}; // Contador de serviços

      Future<void> processDocs(
        List<DocumentSnapshot<Map<String, dynamic>>> docs,
      ) async {
        for (final doc in docs) {
          final data = doc.data();
          if (data == null) continue;

          final dateStr = (data['date'] as String?) ?? (data['dateTime'] as String?) ?? '';
          final status = (data['status'] as String?) ?? 'pending';
          final priceValue = data['price'];
          double price;

          if (priceValue is num) {
            price = priceValue.toDouble();
          } else if (priceValue is String) {
            price = double.tryParse(priceValue) ?? _getServicePrice(data['service'] ?? '');
          } else {
            price = _getServicePrice(data['service'] ?? '');
          }

          final serviceName = (data['service'] as String?) ?? 'Desconhecido';

          // Receita Estimada (Hoje): confirmed OU completed agendados para hoje
          if (dateStr.startsWith(todayStr)) {
            todayAppointmentsCount++;
            if (status == 'confirmed' || status == 'completed') {
              estimatedRevenue += price;
            }
          }

          // Receita Total: Apenas completed desde sempre
          if (status == 'completed') {
            totalCuts++;
            totalRevenue += price;

            // Contar serviços mais vendidos
            serviceCount[serviceName] = (serviceCount[serviceName] ?? 0) + 1;
          }
        }
      }

      await processDocs(allAppointmentsSnapshot.docs.cast<DocumentSnapshot<Map<String, dynamic>>>());


      // Encontrar serviço mais vendido
      String topService = 'N/A';
      int topServiceCount = 0;
      if (serviceCount.isNotEmpty) {
        final topEntry = serviceCount.entries.reduce((a, b) => a.value > b.value ? a : b);
        topService = topEntry.key;
        topServiceCount = topEntry.value;
      }

      return {
        'todayAppointments': todayAppointmentsCount,
        'newClients': newClients.size,
        'activeBarbers': activeClients.size,
        'estimatedRevenue': estimatedRevenue,
        'totalCuts': totalCuts,
        'totalRevenue': totalRevenue,
        'topService': topService,
        'topServiceCount': topServiceCount,
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {
        'todayAppointments': 0,
        'newClients': 0,
        'activeBarbers': 0,
        'estimatedRevenue': 0.0,
        'totalCuts': 0,
        'totalRevenue': 0.0,
        'topService': 'N/A',
        'topServiceCount': 0,
      };
    }
  }

  
 // Obter agendamentos recentes (default)
Stream<List<AppointmentModel>> getRecentAppointments() {
  return getAllAppointments().map((appointments) {
    final sorted = List<AppointmentModel>.from(appointments)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(10).toList();
  });
}

 // Cache em memória — evita re-buscar o mesmo profissional/serviço a cada
// snapshot. Invalida-se sozinho quando o profissional/serviço muda, porque
// vamos atualizar o cache sempre que buscarmos de novo (ver abaixo).

// Obter todos os agendamentos (default)
Stream<List<AppointmentModel>> getAllAppointments() {
  return _firestore.collection('agendamentos').snapshots().asyncMap((snapshot) async {
    final docs = snapshot.docs.cast<DocumentSnapshot<Map<String, dynamic>>>();

    // 1ª passagem: recolhe, sem duplicados, os IDs de profissional e as
    // combinações serviço+profissional que ainda não estão em cache.
    final Set<String> profIdsToFetch = {};
    final Set<String> serviceKeysToFetch = {};

    for (final doc in docs) {
      final data = doc.data();
      if (data == null) continue;

      final professionalId = data['professional'] as String? ?? '';
      if (professionalId.isNotEmpty && !_professionalNameCache.containsKey(professionalId)) {
        profIdsToFetch.add(professionalId);
      }

      final duration = (data['duracao'] ?? data['duration']) as int?;
      final serviceName = data['service'] as String? ?? '';
      if ((duration == null || duration == 0) && serviceName.isNotEmpty && professionalId.isNotEmpty) {
        final key = '$serviceName|$professionalId';
        if (!_serviceDurationCache.containsKey(key)) {
          serviceKeysToFetch.add(key);
        }
      }
    }

    // 2ª passagem: resolve profissionais em lotes de 10 (limite do whereIn),
    // todos em paralelo — em vez de 1 await por agendamento.
    if (profIdsToFetch.isNotEmpty) {
      final ids = profIdsToFetch.toList();
      const batchSize = 10;
      final batches = <Future<void>>[];
      for (var i = 0; i < ids.length; i += batchSize) {
        final batchIds = ids.sublist(i, i + batchSize > ids.length ? ids.length : i + batchSize);
        batches.add(
          _firestore
              .collection('profissionais')
              .where(FieldPath.documentId, whereIn: batchIds)
              .get()
              .then((snap) {
            for (final d in snap.docs) {
              _professionalNameCache[d.id] = d.data()['name'] ?? d.id;
            }
          }).catchError((e) => print('Error fetching professional batch: $e')),
        );
      }
      await Future.wait(batches);
    }

    // 3ª passagem: resolve durações de serviço que ainda faltam, em paralelo.
    if (serviceKeysToFetch.isNotEmpty) {
      final futures = serviceKeysToFetch.map((key) async {
        final parts = key.split('|');
        final serviceName = parts[0];
        final professionalId = parts[1];
        try {
          final q = await _firestore
              .collection('servicos')
              .where('nome', isEqualTo: serviceName)
              .where('profissionalId', isEqualTo: professionalId)
              .limit(1)
              .get();
          if (q.docs.isNotEmpty) {
            _serviceDurationCache[key] = (q.docs.first.data()['duracao'] ?? 0).toInt();
          }
        } catch (e) {
          print('Error fetching service duration: $e');
        }
      });
      await Future.wait(futures);
    }

    // 4ª passagem: monta os AppointmentModel só com dados já em memória —
    // nenhum await aqui, é tudo síncrono e instantâneo.
    final appointments = docs.map((doc) => _mapBookingToAppointmentFast(doc, sourceDb: '(default)')).toList();
    appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return appointments;
  });
}

// Versão sem awaits — usa os caches já preenchidos por getAllAppointments().
AppointmentModel _mapBookingToAppointmentFast(
  DocumentSnapshot<Map<String, dynamic>> doc, {
  required String sourceDb,
}) {
  final data = doc.data() ?? <String, dynamic>{};
  DateTime parsedDate;
  final dateStr = data['date'] ?? '';
  final timeStr = data['time'] ?? '00:00';

  try {
    final timeParts = timeStr.split(':');
    final hour = timeParts[0].padLeft(2, '0');
    final minute = timeParts.length > 1 ? timeParts[1].padLeft(2, '0') : '00';
    parsedDate = DateTime.parse('${dateStr}T$hour:$minute:00');
  } catch (e) {
    try {
      parsedDate = DateTime.parse(dateStr);
    } catch (e2) {
      parsedDate = DateTime.now();
    }
  }

  final professionalId = data['professional'] as String? ?? '';
  final barberName = _professionalNameCache[professionalId] ?? professionalId;

  final serviceName = data['service'] as String? ?? '';
  int duration = (data['duracao'] ?? data['duration']) as int? ?? 0;
  if (duration == 0) {
    duration = _serviceDurationCache['$serviceName|$professionalId'] ?? _getServiceDuration(serviceName);
  }

  DateTime? concludedAt;
  if (data['concludedAt'] != null) {
    if (data['concludedAt'] is Timestamp) {
      concludedAt = (data['concludedAt'] as Timestamp).toDate();
    } else if (data['concludedAt'] is String) {
      try {
        concludedAt = DateTime.parse(data['concludedAt']);
      } catch (_) {}
    }
  }

  return AppointmentModel(
    id: '${sourceDb}_${doc.id}',
    clientId: data['userId'] ?? data['anonymousId'] ?? '',
    clientName: data['name'] ?? '',
    clientPhone: data['phone'] ?? '',
    barberId: professionalId,
    barberName: barberName,
    serviceName: serviceName,
    price: (data['price'] ?? _getServicePrice(serviceName)).toDouble(),
    duration: duration,
    dateTime: parsedDate,
    status: _mapStatus(data['status'] ?? 'pending'),
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    concludedAt: concludedAt,
  );
}


  // Mapear dados de 'agendamentos' para AppointmentModel
  //
  // Mantemos este wrapper para compatibilidade com partes do código que ainda chamam
  // _mapBookingToAppointment(doc) diretamente.
  // Wrapper usado por chamadas existentes no arquivo
  // (mantém comportamento padrão: assume falcaobarbershop)
  Future<AppointmentModel> _mapBookingToAppointment(DocumentSnapshot doc) async {
    return _mapBookingToAppointmentLegacy(
      doc as DocumentSnapshot<Map<String, dynamic>>,
      sourceDb: '(default)',
    );
  }


  Future<AppointmentModel> _mapBookingToAppointmentLegacy(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String sourceDb,
  }) async {
    final data = doc.data() ?? <String, dynamic>{};
    DateTime parsedDate;
    final dateStr = data['date'] ?? '';
    final timeStr = data['time'] ?? '00:00';

    try {
      // Garantir que o horário tenha formato HH:MM válido (com zeros à esquerda)
      final timeParts = timeStr.split(':');
      final hour = timeParts[0].padLeft(2, '0');
      final minute = timeParts.length > 1 ? timeParts[1].padLeft(2, '0') : '00';
      final formattedTime = '$hour:$minute';

      // Combine date and time strings to create full datetime
      final combinedDateTime = '${dateStr}T${formattedTime}:00';
      parsedDate = DateTime.parse(combinedDateTime);
    } catch (e) {
      // Fallback: try parsing just the date
      try {
        parsedDate = DateTime.parse(dateStr);
      } catch (e2) {
        // Final fallback to current time
        parsedDate = DateTime.now();
      }
    }

    // Fetch professional name
    String barberName = data['professional'] ?? '';
    if (barberName.isNotEmpty) {
      try {
        final profDoc = await _firestore.collection('profissionais').doc(barberName).get();
        if (profDoc.exists) {
          barberName = profDoc.data()?['name'] ?? barberName;
        }
      } catch (e) {
        // Keep the original barberName if fetch fails
      }
    }

    // Fetch service duration (supports both legacy and new field names)
    int duration = (data['duracao'] ?? data['duration']) ?? 0;

    if (duration == 0) {
      // Try to fetch from services collection
      final serviceName = data['service'] ?? '';
      final professionalId = data['professional'] ?? '';
      if (serviceName.isNotEmpty && professionalId.isNotEmpty) {
        try {
          final servicesQuery = await _firestore
              .collection('servicos')
              .where('nome', isEqualTo: serviceName)
              .where('profissionalId', isEqualTo: professionalId)
              .limit(1)
              .get();
          
          if (servicesQuery.docs.isNotEmpty) {
            duration = (servicesQuery.docs.first.data()['duracao'] ?? 0).toInt();
          }
        } catch (e) {
          // Keep duration as 0 if fetch fails
        }
      }
      
      // Fallback to default durations if still 0
      if (duration == 0) {
        duration = _getServiceDuration(serviceName);
      }
    }

    // Parse concludedAt if it exists
    DateTime? concludedAt;
    if (data['concludedAt'] != null) {
      if (data['concludedAt'] is Timestamp) {
        concludedAt = (data['concludedAt'] as Timestamp).toDate();
      } else if (data['concludedAt'] is String) {
        try {
          concludedAt = DateTime.parse(data['concludedAt']);
        } catch (e) {
          // Keep concludedAt as null if parsing fails
        }
      }
    }

    return AppointmentModel(
      // Prefixa para evitar colisão caso o doc.id exista nas duas bases
      id: '${sourceDb}_${doc.id}',
      clientId: data['userId'] ?? data['anonymousId'] ?? '',
      clientName: data['name'] ?? '',
      clientPhone: data['phone'] ?? '',
      barberId: data['professional'] ?? '', // Usar professional como barberId
      barberName: barberName,
      serviceName: data['service'] ?? '',
      price: (data['price'] ?? _getServicePrice(data['service'] ?? '')).toDouble(), // Usar preço do Firestore ou calcular baseado no serviço
      duration: duration,
      dateTime: parsedDate,
      status: _mapStatus(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      concludedAt: concludedAt,
    );
  }



  // Obter duração baseado no nome do serviço (fallback)
  int _getServiceDuration(String serviceName) {
    const serviceDurations = {
      'Corte de Cabelo': 30,
      'Barba': 20,
      'Corte + Barba': 45,
      'Sobrancelha': 10,
    };
    return serviceDurations[serviceName] ?? 30;
  }

  // Mapear status do booking para status do appointment
  String _mapStatus(String bookingStatus) {
    switch (bookingStatus) {
      case 'confirmed':
        return 'confirmed';
      case 'canceled':
      case 'cancelado':
        return 'cancelled';
      case 'rejected':
        return 'cancelled';
      case 'completed':
        return 'completed';
      default:
        return 'pending';
    }
  }

  // Obter preço baseado no nome do serviço
  double _getServicePrice(String serviceName) {
    const servicePrices = {
      'Corte de Cabelo': 15.0,
      'Barba': 10.0,
      'Corte + Barba': 25.0,
      'Sobrancelha': 5.0,
    };
    return servicePrices[serviceName] ?? 0.0;
  }

  // Obter barbeiros ativos
  Stream<List<BarberModel>> getActiveBarbers() {
    return _firestore
        .collection('barbers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BarberModel.fromMap(doc.data())).toList());
  }

  // Obter dados do gráfico semanal
  Future<List<int>> getWeeklyAppointmentsData() async {
    try {
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      final weeklyData = List<int>.filled(7, 0); // Monday to Sunday

      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        final nextDay = day.add(const Duration(days: 1));
        final dayStr = day.toString().substring(0, 10);
        final nextDayStr = nextDay.toString().substring(0, 10);

        final appointments = await _firestore
            .collection('agendamentos')
            .where('date', isGreaterThanOrEqualTo: dayStr)
            .where('date', isLessThan: nextDayStr)
            .get();

        weeklyData[i] = appointments.size;
      }

      return weeklyData;
    } catch (e) {
      // print('Error getting weekly appointments data: $e');
      return List<int>.filled(7, 0);
    }
  }

  // Confirmar agendamento
  Future<void> confirmAppointment(String appointmentId) async {
    try {
      final parts = appointmentId.split('_');
      if (parts.length < 2) {
        // legado (sem prefixo)
        await _firestore.collection('agendamentos').doc(appointmentId).update({
          'status': 'confirmed',
        });

        _sendConfirmationEmail(appointmentId);

        final doc = await _firestore.collection('agendamentos').doc(appointmentId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['userId'] != null) {
            final userDoc = await _firestore.collection('clientes').doc(data['userId']).get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              (userData['points'] ?? 0.0).toDouble();
          
            }
          }
        }
        return;
      }

      // No modo single-DB, o appointmentId deve ser o id real do doc.
      final originalDocId = parts.sublist(1).join('_');

      await _firestore.collection('agendamentos').doc(originalDocId).update({
        'status': 'confirmed',
      });


      // Send confirmation email: precisa do doc original (sem prefixo) no mesmo banco
      // (para evitar erro de compilação, manter usando o fluxo existente legado do _firestore)
      _sendConfirmationEmail(originalDocId);

      // Check user account and add points based on the same DB we updated
      final doc = await _firestore.collection('agendamentos').doc(originalDocId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['userId'] != null) {
            final userDoc = await _firestore.collection('clientes').doc(data['userId']).get();

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final currentPoints = (userData['points'] ?? 0.0).toDouble();
            if (currentPoints < 100) {
              await _firestore.collection('clientes').doc(data['userId']).update({

                'points': currentPoints + 10,
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error confirming appointment: $e');
      rethrow;
    }
  }

  // Método separado para enviar email de confirmação (não bloqueia a UI)
  Future<void> _sendConfirmationEmail(String appointmentId) async {
    try {
      final doc = await _firestore.collection('agendamentos').doc(appointmentId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;

      // Fetch professional name
      String professionalName = data['professional'] ?? 'Não informado';
      if (professionalName != 'Não informado') {
        try {
          final profDoc = await _firestore.collection('profissionais').doc(professionalName).get();
          if (profDoc.exists) {
            professionalName = profDoc.data()?['name'] ?? professionalName;
          }
        } catch (e) {
          // Keep the original professionalName if fetch fails
        }
      }

      // Parse date safely
      String formattedDate = 'Data não informada';
      try {
        final dateStr = data['date'] ?? '';
        if (dateStr.isNotEmpty) {
          final parsedDate = DateTime.parse(dateStr);
          formattedDate = '${parsedDate.toLocal().toString().split(' ')[0]} (${_getWeekdayName(parsedDate.weekday)})';
        }
      } catch (e) {
        print('Error parsing date: $e');
      }

      // Get price from appointment data or calculate based on service
      final priceValue = data['price'];
      double price;
      if (priceValue is num) {
        price = priceValue.toDouble();
      } else if (priceValue is String) {
        price = double.tryParse(priceValue) ?? _getServicePrice(data['service'] ?? '');
      } else {
        price = _getServicePrice(data['service'] ?? '');
      }

      final emailService = EmailService();
      final success = await emailService.sendBookingConfirmedEmail(
        service: data['service'] ?? 'Não informado',
        professional: professionalName,
        date: formattedDate,
        time: data['time'] ?? '',
        barbearia: data['barbearia'] ?? 'Falcão Barbershop',
        name: data['name'] ?? 'Cliente',
        phone: data['phone'] ?? 'Não informado',
        email: data['email'] ?? 'cliente@naoinformado.com',
        price: price,
      );

      if (success) {
        print('✅ Email de confirmação enviado com sucesso!');
      } else {
        print('❌ Erro ao enviar email de confirmação');
      }
    } catch (e) {
      print('Error sending confirmation email: $e');
    }
  }

  // Método separado para enviar email de cancelamento (não bloqueia a UI)
  Future<void> _sendCancellationEmail(
    String appointmentId, {
    required String sourceDb,
  }) async {
    try {
      final targetFirestore =
          _firestore;

      final doc = await targetFirestore.collection('agendamentos').doc(appointmentId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;

      // Fetch professional name
      String professionalName = data['professional'] ?? 'Não informado';
      if (professionalName != 'Não informado') {
        try {
          final profDoc = await _firestore.collection('profissionais').doc(professionalName).get();
          if (profDoc.exists) {
            professionalName = profDoc.data()?['name'] ?? professionalName;
          }
        } catch (e) {
          // Keep the original professionalName if fetch fails
        }
      }

      // Get price from appointment data or calculate based on service
      final priceValue = data['price'];
      double price;
      if (priceValue is num) {
        price = priceValue.toDouble();
      } else if (priceValue is String) {
        price = double.tryParse(priceValue) ?? _getServicePrice(data['service'] ?? '');
      } else {
        price = _getServicePrice(data['service'] ?? '');
      }

      final emailService = EmailService();
      final success = await emailService.sendBookingCancelledEmail(
        service: data['service'] ?? 'Não informado',
        professional: professionalName,
        date: '${DateTime.parse(data['date']).toLocal().toString().split(' ')[0]} (${_getWeekdayName(DateTime.parse(data['date']).weekday)})',
        time: data['time'] ?? '',
        barbearia: data['barbearia'] ?? 'Falcão Barbershop',
        name: data['name'] ?? 'Cliente',
        phone: data['phone'] ?? 'Não informado',
        email: data['email'] ?? 'cliente@naoinformado.com',
        price: price,
      );

      if (success) {
        print('✅ Email de cancelamento enviado com sucesso!');
      } else {
        print('❌ Erro ao enviar email de cancelamento');
      }
    } catch (e) {
      print('Error sending cancellation email: $e');
    }
  }

  // Backward-compatible wrapper (mantém assinatura, mas opera no default)


  // Cancelar agendamento
  //
  // Importante: na lista merged (default + falcaobarbershop) o id do AppointmentModel
  // pode vir prefixado no formato: "<sourceDb>_<originalDocId>".
  // Para cancelar corretamente, precisamos rotear a atualização para a base correta
  // e usar o originalDocId (sem prefixo) no update/delete.
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      final parts = appointmentId.split('_');
      final originalDocId = parts.length < 2 ? appointmentId : parts.sublist(1).join('_');

      await _firestore.collection('agendamentos').doc(originalDocId).update({
        'status': 'cancelado',
      });

      _sendCancellationEmail(originalDocId, sourceDb: '(default)');

    } catch (e) {
      print('Error cancelling appointment: $e');
      rethrow;
    }
  }

  // Obter agendamentos por email (para usuários anônimos)
  Future<List<AppointmentModel>> getAppointmentsByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('agendamentos')
          .where('email', isEqualTo: email)
          .orderBy('date', descending: true)
          .get();
      return await Future.wait(query.docs.map((doc) => _mapBookingToAppointment(doc)));
    } catch (e) {
      print('Error getting appointments by email: $e');
      return [];
    }
  }

  // Marcar agendamento como concluído
  Future<void> completeAppointment(String appointmentId) async {
    try {
      await _firestore.collection('agendamentos').doc(appointmentId).update({
        'status': 'completed',
        'concludedAt': Timestamp.now(),
      });
    } catch (e) {
      // print('Error completing appointment: $e');
      rethrow;
    }
  }

  // Obter notificações de novos agendamentos (últimas 24h)
  Future<int> getNewAppointmentsCount() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final newAppointments = await _firestore
          .collection('agendamentos')
          .where('createdAt', isGreaterThanOrEqualTo: yesterday)
          .where('status', isEqualTo: 'pending')
          .get();

      return newAppointments.size;
    } catch (e) {
      // print('Error getting new appointments count: $e');
      return 0;
    }
  }

  // Barbearias CRUD
  Stream<List<BarbeariaModel>> getAllBarbearias() {
    return _firestore
        .collection('barbearias')
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BarbeariaModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addBarbearia(BarbeariaModel barbearia) async {
    try {
      final docRef = _firestore.collection('barbearias').doc();
      final barbeariaWithId = BarbeariaModel(
        id: docRef.id,
        name: barbearia.name,
        address: barbearia.address,
        daysHours: barbearia.daysHours,
        phone: barbearia.phone,
        isActive: barbearia.isActive,
      );
      await docRef.set(barbeariaWithId.toMap());
    } catch (e) {
      print('Error adding barbearia: $e');
      rethrow;
    }
  }

  Future<void> updateBarbearia(BarbeariaModel barbearia) async {
    try {
      await _firestore.collection('barbearias').doc(barbearia.id).update(barbearia.toMap());
    } catch (e) {
      print('Error updating barbearia: $e');
      rethrow;
    }
  }

  Future<void> deleteBarbearia(String barbeariaId) async {
    try {
      await _firestore.collection('barbearias').doc(barbeariaId).delete();
    } catch (e) {
      print('Error deleting barbearia: $e');
      rethrow;
    }
  }

  Future<void> toggleBarbeariaActive(String barbeariaId, bool isActive) async {
    try {
      await _firestore.collection('barbearias').doc(barbeariaId).update({
        'isActive': isActive,
      });
    } catch (e) {
      print('Error toggling barbearia active: $e');
      rethrow;
    }
  }

  Future<BarbeariaModel?> getBarbeariaById(String barbeariaId) async {
    try {
      final doc = await _firestore.collection('barbearias').doc(barbeariaId).get();
      if (doc.exists) {
        return BarbeariaModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print('Error getting barbearia: $e');
    }
    return null;
  }

  // Profissionais CRUD
  Stream<List<ProfissionalModel>> getAllProfissionais() {
    return _firestore
        .collection('profissionais')
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ProfissionalModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addProfissional(ProfissionalModel profissional, String password) async {
    try {
      // Criar usuário no Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: profissional.email,
        password: password,
      );

      // Salvar no Firestore como profissional
      final profissionalWithId = profissional.copyWith(
        userId: userCredential.user!.uid,
        id: userCredential.user!.uid, // Usar o mesmo ID do Auth
      );
      await _firestore.collection('profissionais').doc(profissionalWithId.id).set(profissionalWithId.toMap());

      // Também salvar como cliente para permitir login como usuário comum
      UserModel cliente = UserModel(
        uid: userCredential.user!.uid,
        name: profissional.name,
        email: profissional.email,
        phone: profissional.phone,
        city: '', // Pode ser adicionado depois se necessário
        role: 'barbeiro', // Permite login como barbeiro
        createdAt: profissional.createdAt,
      );
      await _firestore.collection('clientes').doc(cliente.uid).set(cliente.toMap());

      // Relogin as admin
      await AuthController().reloginAsAdmin();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Erro ao adicionar profissional: $e';
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'A senha é muito fraca.';
      case 'email-already-in-use':
        return 'Este email já está sendo usado.';
      case 'invalid-email':
        return 'Email inválido.';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }

  Future<void> updateProfissional(ProfissionalModel profissional) async {
    try {
      await _firestore.collection('profissionais').doc(profissional.id).update(profissional.toMap());
    } catch (e) {
      print('Error updating profissional: $e');
      rethrow;
    }
  }

  Future<void> deleteProfissional(String profissionalId) async {
    try {
      await _firestore.collection('profissionais').doc(profissionalId).delete();
    } catch (e) {
      print('Error deleting profissional: $e');
      rethrow;
    }
  }

  Future<void> toggleProfissionalDisponivel(String profissionalId, bool disponivel) async {
    try {
      await _firestore.collection('profissionais').doc(profissionalId).update({
        'disponivel': disponivel,
      });
    } catch (e) {
      print('Error toggling profissional disponivel: $e');
      rethrow;
    }
  }

  Future<void> saveProfissionalUserData(String userId, String name, String email, String phone, DateTime createdAt) async {
    try {
      await _firestore.collection('clientes').doc(userId).set({
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'barbeiro',
        'createdAt': createdAt,
        'points': 0,
      });
    } catch (e) {
      print('Error saving profissional user data: $e');
      rethrow;
    }
  }

  // Clientes CRUD
  Stream<List<UserModel>> getAllClientes() {
    return _firestore
        .collection('clientes')
        .where('role', isEqualTo: 'cliente')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  Future<void> updateCliente(UserModel cliente) async {
    try {
      await _firestore.collection('clientes').doc(cliente.uid).update(cliente.toMap());
    } catch (e) {
      print('Error updating cliente: $e');
      rethrow;
    }
  }

  Future<void> deleteCliente(String clienteId) async {
    try {
      await _firestore.collection('clientes').doc(clienteId).delete();
    } catch (e) {
      print('Error deleting cliente: $e');
      rethrow;
    }
  }

  Future<void> resetPoints(String clienteId) async {
    try {
      await _firestore.collection('clientes').doc(clienteId).update({
        'points': 0.0,
      });
    } catch (e) {
      print('Error resetting points: $e');
      rethrow;
    }
  }

  Future<void> blockCliente(String clienteId, bool blocked) async {
    try {
      await _firestore.collection('clientes').doc(clienteId).update({
        'blocked': blocked,
      });
    } catch (e) {
      print('Error blocking cliente: $e');
      rethrow;
    }
  }

  Future<AppointmentModel?> getClienteLastAppointment(String clienteId) async {
    try {
      final query = await _firestore
          .collection('agendamentos')
          .where('userId', isEqualTo: clienteId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return _mapBookingToAppointment(query.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting last appointment: $e');
      return null;
    }
  }

  Future<List<AppointmentModel>> getClienteAppointmentsHistory(String clienteId, {int limit = 5}) async {
    try {
      final query = await _firestore
          .collection('agendamentos')
          .where('userId', isEqualTo: clienteId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      return await Future.wait(query.docs.map((doc) => _mapBookingToAppointment(doc)));
    } catch (e) {
      print('Error getting appointments history: $e');
      return [];
    }
  }

  Future<int> getClienteAppointmentsCount(String clienteId) async {
    try {
      final query = await _firestore
          .collection('agendamentos')
          .where('userId', isEqualTo: clienteId)
          .get();
      return query.size;
    } catch (e) {
      print('Error getting appointments count: $e');
      return 0;
    }
  }

  // Obter mapa de últimos agendamentos de todos os clientes (para filtros)
  Future<Map<String, DateTime?>> getClientesLastAppointmentsMap(List<String> clienteIds) async {
    try {
      final Map<String, DateTime?> result = {};
      
      // Fetch all appointments for these clients
      if (clienteIds.isEmpty) return result;

      // Get all appointments
      final query = await _firestore
          .collection('agendamentos')
          .where('userId', whereIn: clienteIds)
          .orderBy('date', descending: true)
          .get();

      // Group by clientId and get the most recent
      for (var doc in query.docs) {
        final data = doc.data();
        final clientId = data['userId'] as String?;
        if (clientId != null && !result.containsKey(clientId)) {
          final dateStr = data['date'] as String?;
          if (dateStr != null) {
            try {
              result[clientId] = DateTime.parse(dateStr);
            } catch (e) {
              result[clientId] = null;
            }
          }
        }
      }

      return result;
    } catch (e) {
      print('Error getting clients last appointments map: $e');
      return {};
    }
  }

  // Calcular meses desde o último agendamento
  int getMonthsSinceLastAppointment(DateTime? lastAppointment) {
    if (lastAppointment == null) return -1; // No appointments
    
    final now = DateTime.now();
    final difference = now.difference(lastAppointment);
    return (difference.inDays / 30).floor();
  }

  // VIP Plans CRUD
  Stream<List<VipPlanModel>> getAllVipPlans() {
    return _firestore
        .collection('planos_vip')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => VipPlanModel.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> addVipPlan(VipPlanModel plan) async {
    try {
      final docRef = _firestore.collection('planos_vip').doc();
      final planWithId = plan.copyWith(id: docRef.id);
      await docRef.set(planWithId.toMap());
    } catch (e) {
      print('Error adding VIP plan: $e');
      rethrow;
    }
  }

  Future<void> updateVipPlan(VipPlanModel plan) async {
    try {
      await _firestore.collection('planos_vip').doc(plan.id).update(plan.toMap());
    } catch (e) {
      print('Error updating VIP plan: $e');
      rethrow;
    }
  }

  Future<void> deleteVipPlan(String planId) async {
    try {
      await _firestore.collection('planos_vip').doc(planId).delete();
    } catch (e) {
      print('Error deleting VIP plan: $e');
      rethrow;
    }
  }

  Future<void> toggleVipPlanActive(String planId, bool isActive) async {
    try {
      await _firestore.collection('planos_vip').doc(planId).update({
        'isActive': isActive,
      });
    } catch (e) {
      print('Error toggling VIP plan active: $e');
      rethrow;
    }
  }

  Future<int> getVipPlanSubscribersCount(String planId) async {
    try {
      final query = await _firestore
          .collection('subscricoes_vip')
          .where('planoId', isEqualTo: planId)
          .where('status', isEqualTo: 'ativo')
          .get();
      return query.size;
    } catch (e) {
      print('Error getting VIP plan subscribers count: $e');
      return 0;
    }
  }

  // Settings CRUD
  Future<SettingsModel?> getSettings() async {
    try {
      final doc = await _firestore.collection('settings').doc('main').get();
      if (doc.exists) {
        return SettingsModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting settings: $e');
      return null;
    }
  }

  Future<void> updateSettings(SettingsModel settings) async {
    try {
      await _firestore.collection('settings').doc('main').set(settings.toMap());
    } catch (e) {
      print('Error updating settings: $e');
      rethrow;
    }
  }

  Future<SettingsModel> getOrCreateDefaultSettings() async {
    final existing = await getSettings();
    if (existing != null) {
      return existing;
    }

    // Create default settings
    final defaultSettings = SettingsModel(
      id: 'main',
      barbeariaNome: 'Falcão Barbershop',
      email: '',
      instagram: '',
      horarioFuncionamento: 'Segunda a sábado: 09h às 19h',
      descricaoCurta: 'A melhor barbearia da cidade',
      subDescricao: '',
      whatsApp: '',
      diasAtendimento: ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado'],
      turnos: {
        'manha': {'inicio': '09:00', 'fim': '12:00'},
        'tarde': {'inicio': '14:00', 'fim': '18:00'},
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await updateSettings(defaultSettings);
    return defaultSettings;
  }

  // Serviços CRUD
  Stream<List<ServiceModel>> getAllActiveServices() {
    return _firestore
        .collection('servicos')
        .where('ativo', isEqualTo: true)
        .orderBy('nome')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ServiceModel.fromMap(doc.data())).toList());
  }

  // Obter serviços de um profissional específico
  Stream<List<ServiceModel>> getServicesByProfissional(String profissionalId) {
    return _firestore
        .collection('servicos')
        .where('profissionalId', isEqualTo: profissionalId)
        .snapshots()
        .map((snapshot) {
          final services = snapshot.docs.map((doc) => ServiceModel.fromMap(doc.data())).toList();
          // Ordenar manualmente no cliente para evitar necessidade de índice
          services.sort((a, b) => a.nome.compareTo(b.nome));
          return services;
        });
  }

  // Adicionar serviço para um profissional
  Future<void> addServiceToProfissional(ServiceModel service) async {
    try {
      final docRef = _firestore.collection('servicos').doc();
      final serviceWithId = service.copyWith(id: docRef.id);
      await docRef.set(serviceWithId.toMap());
    } catch (e) {
      print('Error adding service to professional: $e');
      rethrow;
    }
  }

  // Atualizar serviço de um profissional
  Future<void> updateServiceProfissional(ServiceModel service) async {
    try {
      await _firestore.collection('servicos').doc(service.id).update(service.toMap());
    } catch (e) {
      print('Error updating professional service: $e');
      rethrow;
    }
  }

  // Deletar serviço de um profissional
  Future<void> deleteServiceFromProfissional(String serviceId) async {
    try {
      await _firestore.collection('servicos').doc(serviceId).delete();
    } catch (e) {
      print('Error deleting service from professional: $e');
      rethrow;
    }
  }

  // Alternar status ativo de um serviço
  Future<void> toggleServiceStatus(String serviceId, bool ativo) async {
    try {
      await _firestore.collection('servicos').doc(serviceId).update({
        'ativo': ativo,
        'atualizadoEm': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error toggling service status: $e');
      rethrow;
    }
  }

  // VIP Subscriptions CRUD
  Stream<List<VipSubscriptionModel>> getAllVipSubscriptions() {
    return _firestore
        .collection('subscricoes_vip')
        .orderBy('dataSubscricao', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => VipSubscriptionModel.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> activateVipSubscription(String subscriptionId) async {
    try {
      final now = DateTime.now();
      final renewalDate = now.add(const Duration(days: 30));
      await _firestore.collection('subscricoes_vip').doc(subscriptionId).update({
        'status': 'ativo',
        'dataAtivacao': Timestamp.fromDate(now),
        'dataRenovacao': Timestamp.fromDate(renewalDate),
      });
    } catch (e) {
      print('Error activating VIP subscription: $e');
      rethrow;
    }
  }

  Future<void> cancelVipSubscription(String subscriptionId) async {
    try {
      await _firestore.collection('subscricoes_vip').doc(subscriptionId).update({
        'status': 'cancelado',
      });
    } catch (e) {
      print('Error cancelling VIP subscription: $e');
      rethrow;
    }
  }

  Future<void> updateVipSubscriptionStatus(String subscriptionId, String newStatus) async {
    try {
      final Map<String, dynamic> updateData = {'status': newStatus};

      if (newStatus == 'ativo') {
        final now = DateTime.now();
        final renewalDate = now.add(const Duration(days: 30));
        updateData['dataAtivacao'] = Timestamp.fromDate(now);
        updateData['dataRenovacao'] = Timestamp.fromDate(renewalDate);
      }

      await _firestore.collection('subscricoes_vip').doc(subscriptionId).update(updateData);
    } catch (e) {
      print('Error updating VIP subscription status: $e');
      rethrow;
    }
  }

  Future<VipSubscriptionModel?> getUserVipSubscription(String userId) async {
    try {
      final query = await _firestore
          .collection('subscricoes_vip')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'ativo')
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return VipSubscriptionModel.fromMap(query.docs.first.id, query.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error getting user VIP subscription: $e');
      return null;
    }
  }

  Future<String> getUserNameById(String userId) async {
    try {
      final doc = await _firestore.collection('clientes').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['name'] ?? 'Desconhecido';
      }
      return 'Desconhecido';
    } catch (e) {
      print('Error getting user name: $e');
      return 'Desconhecido';
    }
  }

  Future<VipPlanModel?> getVipPlanById(String planId) async {
    try {
      final doc = await _firestore.collection('planos_vip').doc(planId).get();
      if (doc.exists) {
        return VipPlanModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting VIP plan: $e');
      return null;
    }
  }

  Future<void> addPoints(String clienteId, int points) async {
    try {
      final doc = await _firestore.collection('clientes').doc(clienteId).get();
      if (doc.exists) {
        final currentPoints = (doc.data()?['points'] ?? 0.0).toDouble();
        await _firestore.collection('clientes').doc(clienteId).update({
          'points': currentPoints + points,
        });
      }
    } catch (e) {
      print('Error adding points: $e');
      rethrow;
    }
  }

  // Notification CRUD - Now based on appointment alerts
  Stream<List<NotificationModel>> getAllNotifications() {
    return getAllAppointments().asyncMap((appointments) async {
      // Create notifications from recent appointments (last 7 days)
      final recentAppointments = appointments.where((appointment) {
        final difference = DateTime.now().difference(appointment.createdAt);
        return difference.inDays <= 7;
      }).toList();

      // Sort by created date descending
      recentAppointments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Get read status for all notifications
      final readStatuses = await _getReadStatuses(recentAppointments.map((a) => a.id).toList());

      // Convert appointments to notifications with read status
      return recentAppointments.map((appointment) {
        final isRead = readStatuses[appointment.id] ?? false;
        return NotificationModel.fromAppointment(appointment, appointment.status).copyWith(lida: isRead);
      }).toList();
    });
  }

  Future<Map<String, bool>> _getReadStatuses(List<String> notificationIds) async {
    try {
      final readStatuses = <String, bool>{};

      // Firestore 'whereIn' supports maximum 30 elements, so we need to batch the queries
      const int batchSize = 30;
      for (int i = 0; i < notificationIds.length; i += batchSize) {
        final endIndex = (i + batchSize < notificationIds.length) ? i + batchSize : notificationIds.length;
        final batchIds = notificationIds.sublist(i, endIndex);

        final readDocs = await _firestore.collection('admin_notifications_read').where(FieldPath.documentId, whereIn: batchIds).get();

        for (final doc in readDocs.docs) {
          readStatuses[doc.id] = (doc.data()['read'] as bool?) ?? false;
        }
      }

      return readStatuses;
    } catch (e) {
      print('Error getting read statuses: $e');
      return {};
    }
  }

  Future<void> addNotification(String titulo, String mensagem) async {
    // This method is no longer used since we don't create manual notifications
    // Kept for compatibility but does nothing
    print('Manual notifications are no longer supported. Notifications are now based on appointments.');
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('admin_notifications_read').doc(notificationId).set({
        'read': true,
        'readAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      final notifications = await getAllNotifications().first;
      for (final notification in notifications) {
        await _firestore.collection('admin_notifications_read').doc(notification.id).set({
          'read': true,
          'readAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    // Since notifications are now based on appointments, we can't delete them
    // This is just for UI state management
    print('Cannot delete appointment-based notifications');
  }

  Stream<int> getUnreadNotificationsCount() {
    getAllNotifications().listen((notifications) {
      final count = notifications.where((notification) => !notification.lida).length;
      _unreadCountController.add(count);
    }).onError((error, stackTrace) {
      print('Error getting unread notifications count: $error');
      _unreadCountController.add(0);
    });
    return _unreadCountController.stream;
  }

  // Posts CRUD
  Stream<List<PostModel>> getAllPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromMap(doc.data())).toList());
  }

  Future<void> addPost(PostModel post) async {
    try {
      final docRef = _firestore.collection('posts').doc();
      final postWithId = post.copyWith(id: docRef.id);
      print('DEBUG addPost: postWithId.toMap() = ${postWithId.toMap()}');
      await docRef.set(postWithId.toMap());
      print('DEBUG addPost: Post adicionado com sucesso, id = ${docRef.id}');
    } catch (e) {
      print('Error adding post: $e');
      rethrow;
    }
  }

  Future<void> updatePost(PostModel post) async {
    try {
      print('DEBUG updatePost: post.toMap() = ${post.toMap()}');
      await _firestore.collection('posts').doc(post.id).update(post.toMap());
      print('DEBUG updatePost: Post atualizado com sucesso, id = ${post.id}');
    } catch (e) {
      print('Error updating post: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  Future<PostModel?> getPostById(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      if (doc.exists) {
        return PostModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting post: $e');
      return null;
    }
  }

  // Helper method to send appointment update email
  Future<void> _sendAppointmentUpdateEmail(Map<String, dynamic> appointmentData, String newServiceName, String newProfessionalName, String updateType) async {
    try {
      final emailService = EmailService();
      final success = await emailService.sendAppointmentUpdateEmail(
        service: newServiceName,
        professional: newProfessionalName,
        date: '${DateTime.parse(appointmentData['date']).toLocal().toString().split(' ')[0]} (${_getWeekdayName(DateTime.parse(appointmentData['date']).weekday)})',
        time: appointmentData['time'] ?? '',
        barbearia: appointmentData['barbearia'] ?? 'Falcão Barbershop',
        name: appointmentData['name'] ?? 'Cliente',
        phone: appointmentData['phone'] ?? 'Não informado',
        email: appointmentData['email'] ?? 'cliente@naoinformado.com',
        updateType: updateType,
      );

      if (success) {
        print('✅ Email de atualização de agendamento enviado com sucesso!');
      } else {
        print('❌ Erro ao enviar email de atualização de agendamento');
      }
    } catch (e) {
      print('Error sending appointment update email: $e');
    }
  }

  // Update appointment service and professional
  Future<void> updateAppointmentService(String appointmentId, String newServiceName, String newProfessionalId, double newPrice, int newDuration) async {
    try {
      // Get current appointment data
      final appointmentDoc = await _firestore.collection('agendamentos').doc(appointmentId).get();
      if (!appointmentDoc.exists) {
        throw 'Appointment not found';
      }
      final appointmentData = appointmentDoc.data()!;

      // Get professional name
      String professionalName = '';
      if (newProfessionalId.isNotEmpty) {
        final profDoc = await _firestore.collection('profissionais').doc(newProfessionalId).get();
        if (profDoc.exists) {
          professionalName = profDoc.data()?['name'] ?? '';
        }
      }

      await _firestore.collection('agendamentos').doc(appointmentId).update({
        'service': newServiceName,
        'professional': newProfessionalId,
        'price': newPrice,
        'duration': newDuration,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send update email to client
      await _sendAppointmentUpdateEmail(appointmentData, newServiceName, professionalName, 'service');
      print('✅ Email de atualização de serviço enviado com sucesso!');
    } catch (e) {
      print('Error updating appointment service: $e');
      rethrow;
    }
  }

  // Update appointment date and time
  Future<void> updateAppointmentTime(String appointmentId, DateTime newDateTime) async {
    try {
      // Get current appointment data
      final appointmentDoc = await _firestore.collection('agendamentos').doc(appointmentId).get();
      if (!appointmentDoc.exists) {
        throw 'Appointment not found';
      }
      final appointmentData = appointmentDoc.data()!;

      final dateStr = newDateTime.toString().substring(0, 10); // "2024-01-15"
      final timeStr = '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';

      await _firestore.collection('agendamentos').doc(appointmentId).update({
        'date': dateStr,
        'time': timeStr,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get professional name
      String professionalName = appointmentData['professional'] ?? '';
      if (professionalName.isNotEmpty) {
        try {
          final profDoc = await _firestore.collection('profissionais').doc(professionalName).get();
          if (profDoc.exists) {
            professionalName = profDoc.data()?['name'] ?? professionalName;
          }
        } catch (e) {
          // Keep the original professionalName if fetch fails
        }
      }

      // Send update email to client
      await _sendAppointmentUpdateEmail(appointmentData, appointmentData['service'] ?? '', professionalName, 'time');
      print('✅ Email de atualização de horário enviado com sucesso!');
    } catch (e) {
      print('Error updating appointment time: $e');
      rethrow;
    }
  }

  // Deletar agendamento (apenas se cancelado)
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      // Verificar se o agendamento existe e está cancelado
      final doc = await _firestore.collection('agendamentos').doc(appointmentId).get();
      if (!doc.exists) {
        throw 'Agendamento não encontrado';
      }

      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'pending';

      if (status != 'cancelled' && status != 'cancelado') {
        throw 'Apenas agendamentos cancelados podem ser deletados';
      }

      // Deletar o agendamento
      await _firestore.collection('agendamentos').doc(appointmentId).delete();

      print('✅ Agendamento deletado com sucesso!');
    } catch (e) {
      print('Error deleting appointment: $e');
      rethrow;
    }
  }

  // Enviar solicitação de avaliação
  Future<void> sendReviewRequest(String appointmentId) async {
    await _sendReviewRequestEmail(appointmentId);
  }

  // Método auxiliar para obter email do cliente
  Future<String> _getClientEmail(String appointmentId) async {
    final doc = await _firestore.collection('agendamentos').doc(appointmentId).get();
    if (!doc.exists) return '';

    final data = doc.data() as Map<String, dynamic>;

    // Obter email do cliente
    String email = data['email'] ?? '';
    if (email.isEmpty && data['userId'] != null) {
      final userDoc = await _firestore.collection('clientes').doc(data['userId']).get();
      if (userDoc.exists) {
        email = userDoc.data()?['email'] ?? '';
      }
    }

    return email;
  }

  // Método para obter contagem de solicitações de avaliação enviadas para um email
  Future<int> getReviewRequestCount(String email) async {
    if (email.isEmpty) return 0;

    try {
      final query = await _firestore
          .collection('review_requests')
          .where('email', isEqualTo: email)
          .get();

      return query.size;
    } catch (e) {
      print('Error getting review request count: $e');
      return 0;
    }
  }

  // Método para obter email do cliente de um agendamento
  Future<String> getAppointmentClientEmail(String appointmentId) async {
    return await _getClientEmail(appointmentId);
  }

  // Método auxiliar para enviar email de solicitação de avaliação
  Future<void> _sendReviewRequestEmail(String appointmentId) async {
    try {
      final doc = await _firestore.collection('agendamentos').doc(appointmentId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;

      // Obter email do cliente
      String email = data['email'] ?? '';
      if (email.isEmpty && data['userId'] != null) {
        final userDoc = await _firestore.collection('clientes').doc(data['userId']).get();
        if (userDoc.exists) {
          email = userDoc.data()?['email'] ?? '';
        }
      }

      if (email.isEmpty) {
        print('Nenhum email encontrado para solicitação de avaliação');
        return;
      }

      // Obter nome do profissional
      String professionalName = data['professional'] ?? '';
      if (professionalName.isNotEmpty) {
        try {
          final profDoc = await _firestore.collection('profissionais').doc(professionalName).get();
          if (profDoc.exists) {
            professionalName = profDoc.data()?['name'] ?? professionalName;
          }
        } catch (e) {
          // Manter o professionalName original se a busca falhar
        }
      }

      final emailService = EmailService();
      final success = await emailService.sendReviewRequestEmail(
        service: data['service'] ?? '',
        professional: professionalName,
        date: '${DateTime.parse(data['date']).toLocal().toString().split(' ')[0]} (${_getWeekdayName(DateTime.parse(data['date']).weekday)})',
        time: data['time'] ?? '',
        barbearia: data['barbearia'] ?? 'Falcão Barbershop',
        name: data['name'] ?? '',
        phone: data['phone'] ?? '',
        email: email,
        reviewUrl: 'https://www.google.com/search?num=10&sa=X&sca_esv=1bab67044c4ee1f2&hl=en-PT&sxsrf=AE3TifOxbSSMlXTdI-E9zYCuSrbmu-LeRw:1763425062235&q=Falc%C3%A3o+BarberShop+%E2%80%94+Castelo+Branco+Reviews&ved=2ahUKEwiwrrCjtvqQAxXfhP0HHTw4HRkQ7t0BegQICBAI&biw=1536&bih=826&dpr=1.25',
      );

      if (success) {
        // Record the review request in the database
        await _firestore.collection('review_requests').add({
          'email': email,
          'appointmentId': appointmentId,
          'sentAt': Timestamp.now(),
        });
        print('✅ Email de solicitação de avaliação enviado com sucesso!');
      } else {
        print('❌ Erro ao enviar email de solicitação de avaliação');
      }
    } catch (e) {
      print('Error sending review request email: $e');
    }
  }
}