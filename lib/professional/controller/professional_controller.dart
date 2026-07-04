import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../firestore_instance.dart';
import '../../admin/model/appointment_model.dart';
import '../../admin/model/barbearia_model.dart';
import '../../admin/model/notification_model.dart';
import '../../admin/model/profissional_model.dart';
import '../../admin/model/service_model.dart';
import '../../user/model/user_model.dart';
import '../../services/email_service.dart';

class StreamZipSafe {
  // Mantido apenas para evitar quebra por referências antigas.
  // Não será usado nesta controller.
}

class ProfessionalController {
  final FirebaseFirestore _firestore = firestore;
  // Para rodar somente com o Firebase default (instância padrão), remover dependência de uma 2ª instância.
  final FirebaseFirestore _firestoreDefault = firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  String _getWeekdayName(int weekday) {
    const weekdays = ['Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado'];
    return weekdays[weekday - 1];
  }

  // Get current barber profile
Future<UserModel?> getCurrentBarberProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('clientes').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting barber profile: $e');
      return null;
    }
  }

  Stream<List<AppointmentModel>> _mergeTwoAppointmentStreams(
    Stream<List<AppointmentModel>> falcaStream,
    Stream<List<AppointmentModel>> defaultStream,
  ) {
    final controller = StreamController<List<AppointmentModel>>();
    List<AppointmentModel>? latestFalca;
    List<AppointmentModel>? latestDefault;

    StreamSubscription<List<AppointmentModel>>? subFalca;
    StreamSubscription<List<AppointmentModel>>? subDefault;

    void emitIfReady() {
      if (latestFalca != null && latestDefault != null) {
        final all = [...latestFalca!, ...latestDefault!];

        final seen = <String>{};
        final deduped = <AppointmentModel>[];
        for (final a in all) {
          if (seen.add(a.id)) deduped.add(a);
        }

        deduped.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        controller.add(deduped);
      }
    }

    subFalca = falcaStream.listen(
      (value) {
        latestFalca = value;
        emitIfReady();
      },
      onError: controller.addError,
    );

    subDefault = defaultStream.listen(
      (value) {
        latestDefault = value;
        emitIfReady();
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await subFalca?.cancel();
      await subDefault?.cancel();
    };

    return controller.stream;
  }

  // Get barber's appointments (today and future) - merges default + falcaobarbershop
  Stream<List<AppointmentModel>> getBarberAppointments() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    final streamFalca = _firestore
        .collection('agendamentos')
        .where('professional', isEqualTo: user.uid)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapBookingToAppointment(doc, sourceDb: 'falcaobarbershop'))
            .toList());

    final streamDefault = _firestoreDefault
        .collection('agendamentos')
        .where('professional', isEqualTo: user.uid)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapBookingToAppointment(doc, sourceDb: '(default)'))
            .toList());

    return _mergeTwoAppointmentStreams(streamFalca, streamDefault);
  }

  // Get today's appointments - merges default + falcaobarbershop
  Stream<List<AppointmentModel>> getTodayAppointments() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final streamFalca = _firestore
        .collection('agendamentos')
        .where('professional', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final allAppointments = snapshot.docs
              .map((doc) => _mapBookingToAppointment(doc, sourceDb: 'falcaobarbershop'))
              .toList();
          final todayAppointments = allAppointments.where((appointment) {
            return appointment.dateTime.isAfter(today.subtract(const Duration(seconds: 1))) &&
                appointment.dateTime.isBefore(tomorrow);
          }).toList();
          todayAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          return todayAppointments;
        });

    final streamDefault = _firestoreDefault
        .collection('agendamentos')
        .where('professional', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final allAppointments = snapshot.docs
              .map((doc) => _mapBookingToAppointment(doc, sourceDb: '(default)'))
              .toList();
          final todayAppointments = allAppointments.where((appointment) {
            return appointment.dateTime.isAfter(today.subtract(const Duration(seconds: 1))) &&
                appointment.dateTime.isBefore(tomorrow);
          }).toList();
          todayAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          return todayAppointments;
        });

    return _mergeTwoAppointmentStreams(streamFalca, streamDefault);
  }

  // Get completed appointments this month
  Future<int> getMonthlyCompletedAppointments() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final [queryFalca, queryDefault] = await Future.wait([
        _firestore
            .collection('agendamentos')
            .where('professional', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed')
            .get(),
        _firestoreDefault
            .collection('agendamentos')
            .where('professional', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed')
            .get(),
      ]);

      int count = 0;

      for (final query in [queryFalca, queryDefault]) {
        final monthlyAppointments = query.docs.where((doc) {
          final data = doc.data();
          final dateStr = data['date'] ?? DateTime.now().toIso8601String();
          DateTime parsedDate;
          try {
            parsedDate = DateTime.parse(dateStr);
          } catch (e) {
            try {
              parsedDate = DateTime.parse('${dateStr}T00:00:00.000');
            } catch (e2) {
              parsedDate = DateTime.now();
            }
          }
          return parsedDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1)));
        }).toList();

        count += monthlyAppointments.length;
      }

      return count;
    } catch (e) {
      print('Error getting monthly completed appointments: $e');
      return 0;
    }
  }

  // Get next appointment
  Future<AppointmentModel?> getNextAppointment() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      final [queryFalca, queryDefault] = await Future.wait([
        _firestore
            .collection('agendamentos')
            .where('professional', isEqualTo: user.uid)
            .get(),
        _firestoreDefault
            .collection('agendamentos')
            .where('professional', isEqualTo: user.uid)
            .get(),
      ]);

      final allAppointments = [
        ...queryFalca.docs.map((doc) => _mapBookingToAppointment(doc, sourceDb: 'falcaobarbershop')),
        ...queryDefault.docs.map((doc) => _mapBookingToAppointment(doc, sourceDb: '(default)')),
      ];

      final futureAppointments = allAppointments.where((appointment) {
        return appointment.dateTime.isAfter(now) &&
            (appointment.status == 'confirmed' || appointment.status == 'pending');
      }).toList();

      if (futureAppointments.isNotEmpty) {
        futureAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        final nextAppointment = futureAppointments.first;

        // Get client name from appropriate collection
        final clientName = await _getClientName(nextAppointment.clientId);
        return nextAppointment.copyWith(clientName: clientName);
      }
      return null;
    } catch (e) {
      print('Error getting next appointment: $e');
      return null;
    }
  }

  // Helper method to get client name from either 'clientes' or 'clientes_anonimos'
  Future<String> _getClientName(String clientId) async {
    try {
      // First try 'clientes' collection
      final clientDoc = await _firestore.collection('clientes').doc(clientId).get();
      if (clientDoc.exists) {
        final data = clientDoc.data() as Map<String, dynamic>;
        return data['name'] ?? 'Cliente';
      }

      // If not found, try 'clientes_anonimos' collection
      final anonymousDoc = await _firestore.collection('clientes_anonimos').doc(clientId).get();
      if (anonymousDoc.exists) {
        final data = anonymousDoc.data() as Map<String, dynamic>;
        return data['name'] ?? 'Cliente Anônimo';
      }

      return 'Cliente';
    } catch (e) {
      print('Error getting client name: $e');
      return 'Cliente';
    }
  }

  // Update appointment status
  //
  // Importante: no merge default + falcaobarbershop o appointmentId pode vir prefixado:
  //   "<sourceDb>_<originalDocId>"
  // Precisamos rotear o update para a base correta.
  Future<void> updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      final parts = appointmentId.split('_');

      // Map status to Portuguese if needed
      String dbStatus = newStatus;
      if (newStatus == 'cancelled') dbStatus = 'cancelado';

      // Legacy / fallback: sem prefixo => falcaobarbershop
      if (parts.length < 2) {
        await _firestore.collection('agendamentos').doc(appointmentId).update({
          'status': dbStatus,
        });

        if (newStatus == 'confirmed') {
          await _sendAppointmentConfirmationEmail(appointmentId);
        } else if (newStatus == 'cancelled') {
          await _sendAppointmentCancellationEmail(appointmentId);
        }
        return;
      }

      final sourceDb = parts.first;
      final originalDocId = parts.sublist(1).join('_');
      final targetFirestore = sourceDb == '(default)' ? _firestoreDefault : _firestore;

      await targetFirestore.collection('agendamentos').doc(originalDocId).update({
        'status': dbStatus,
      });

      // Enviar email precisa do originalDocId no mesmo banco que contém o doc.
      if (newStatus == 'confirmed') {
        await _sendAppointmentConfirmationEmail(originalDocId, sourceDb: sourceDb);
      } else if (newStatus == 'cancelled') {
        await _sendAppointmentCancellationEmail(originalDocId, sourceDb: sourceDb);
      }
    } catch (e) {
      print('Error updating appointment status: $e');
      rethrow;
    }
  }

  // Send appointment confirmation email
  Future<void> _sendAppointmentConfirmationEmail(
    String appointmentId, {
    String sourceDb = 'falcaobarbershop',
  }) async {
    try {
      final targetFirestore = sourceDb == '(default)' ? _firestoreDefault : _firestore;

      final doc = await targetFirestore.collection('agendamentos').doc(appointmentId).get();
      if (doc.exists) {
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
        final success = await emailService.sendBookingConfirmedEmail(
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
          print('✅ Email de confirmação enviado com sucesso via Firebase!');
        } else {
          print('❌ Erro ao enviar email de confirmação via Firebase');
        }
      }
    } catch (e) {
      print('Error sending confirmation email: $e');
    }
  }

  // Send appointment cancellation email
  Future<void> _sendAppointmentCancellationEmail(
    String appointmentId, {
    String sourceDb = 'falcaobarbershop',
  }) async {
    try {
      final targetFirestore = sourceDb == '(default)' ? _firestoreDefault : _firestore;

      final doc = await targetFirestore.collection('agendamentos').doc(appointmentId).get();
      if (doc.exists) {
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
          print('✅ Email de cancelamento enviado com sucesso via Firebase!');
        } else {
          print('❌ Erro ao enviar email de cancelamento via Firebase');
        }
      }
    } catch (e) {
      print('Error sending cancellation email: $e');
    }
  }

  // Add observation to appointment
  Future<void> addAppointmentObservation(String appointmentId, String observation) async {
    try {
      await _firestore.collection('agendamentos').doc(appointmentId).update({
        'observation': observation,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding observation: $e');
      rethrow;
    }
  }

  // Get barber notifications
  Stream<List<NotificationModel>> getBarberNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notificacoes')
        .where('barbeiroId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationModel.fromMap(doc.id, doc.data())).toList());
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notificacoes').doc(notificationId).update({
        'lida': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Get appointment history (completed and cancelled)
  Stream<List<AppointmentModel>> getAppointmentHistory() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    final streamFalca = _firestore
        .collection('agendamentos')
        .where('professional', isEqualTo: user.uid)
        .where('status', whereIn: ['completed', 'cancelled'])
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapBookingToAppointment(doc, sourceDb: 'falcaobarbershop'))
            .toList());

    final streamDefault = _firestoreDefault
        .collection('agendamentos')
        .where('professional', isEqualTo: user.uid)
        .where('status', whereIn: ['completed', 'cancelled'])
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapBookingToAppointment(doc, sourceDb: '(default)'))
            .toList());

    // mantem ordenação por dateTime (asc) no merge; aqui queremos desc.
    return _mergeTwoAppointmentStreams(streamFalca, streamDefault).map((list) {
      final copied = [...list];
      copied.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return copied;
    });
  }

  // Update barber profile
  Future<void> updateBarberProfile(UserModel updatedProfile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Update email in Firebase Auth if it changed
      if (updatedProfile.email != null && updatedProfile.email != user.email) {
        await user.verifyBeforeUpdateEmail(updatedProfile.email);
        // Note: Email verification will be sent, user needs to verify before login works
      }

      // Update profile in Firestore
      await _firestore.collection('clientes').doc(user.uid).update(updatedProfile.toMap());
    } catch (e) {
      print('Error updating barber profile: $e');
      rethrow;
    }
  }
// Update professional's profile photo URL in the 'profissionais' collection.
Future<void> updateProfilePhoto(String fotoUrl) async {
  try {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final query = await _firestore
        .collection('profissionais')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Documento profissional não encontrado');
    }

    await _firestore.collection('profissionais').doc(query.docs.first.id).update({
      'fotoUrl': fotoUrl,
    });
  } catch (e) {
    print('Error updating profile photo: $e');
    rethrow;
  }
}
  // Get barber's barbearia info
  Future<BarbeariaModel?> getBarberBarbearia(String barbeariaId) async {
    try {
      final doc = await _firestore.collection('barbearias').doc(barbeariaId).get();
      if (doc.exists) {
        return BarbeariaModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting barbearia: $e');
      return null;
    }
  }

  // Map booking data to AppointmentModel
  AppointmentModel _mapBookingToAppointment(DocumentSnapshot doc, {required String sourceDb}) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime parsedDate;
    final dateData = data['date'];
    if (dateData is Timestamp) {
      parsedDate = dateData.toDate();
    } else if (dateData is String) {
      final dateStr = dateData;
      final timeStr = data['time'] ?? '00:00';
      final combinedDateTime = '${dateStr}T${timeStr}:00';
      try {
        parsedDate = DateTime.parse(combinedDateTime);
      } catch (e) {
        try {
          parsedDate = DateTime.parse(dateStr);
        } catch (e2) {
          parsedDate = DateTime.now();
        }
      }
    } else {
      parsedDate = DateTime.now();
    }
    
    // Get duration from data or use default
    int duration = data['duration'] ?? _getServiceDuration(data['service'] ?? '');
    
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
      // composite id to avoid collisions across databases when we merge
      id: '${sourceDb}_${doc.id}',
      clientId: data['userId'] ?? data['anonymousId'] ?? '',
      clientName: data['name'] ?? '',
      clientPhone: data['phone'] ?? '',
      barberId: data['professional'] ?? '',
      barberName: data['professional'] ?? '',
      serviceName: data['service'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      duration: duration,
      dateTime: parsedDate,
      status: _mapStatus(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      concludedAt: concludedAt,
    );
  }

  // Get default service duration
  int _getServiceDuration(String serviceName) {
    const serviceDurations = {
      'Corte de Cabelo': 30,
      'Barba': 20,
      'Corte + Barba': 45,
      'Sobrancelha': 10,
    };
    return serviceDurations[serviceName] ?? 30;
  }

  // Get service price
  double _getServicePrice(String serviceName) {
    const servicePrices = {
      'Corte de Cabelo': 15.0,
      'Barba': 10.0,
      'Corte + Barba': 25.0,
      'Sobrancelha': 5.0,
    };
    return servicePrices[serviceName] ?? 0.0;
  }

  // Map status
  String _mapStatus(String bookingStatus) {
    switch (bookingStatus.toLowerCase()) {
      case 'confirmed':
      case 'confirmado':
        return 'confirmed';
      case 'pending':
      case 'pendente':
        return 'pending';
      case 'canceled':
      case 'cancelled':
      case 'cancelado':
        return 'cancelled';
      case 'completed':
      case 'completado':
        return 'completed';
      default:
        return 'pending';
    }
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Reauthenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } catch (e) {
      print('Error changing password: $e');
      rethrow;
    }
  }

  // Change email
  Future<void> changeEmail(String newEmail, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Reauthenticate user with password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Send email verification for new email
      await user.verifyBeforeUpdateEmail(newEmail);
    } catch (e) {
      print('Error changing email: $e');
      rethrow;
    }
  }

  // Get barber's professional data (schedule, etc.)
  Future<ProfissionalModel?> getCurrentBarberProfessionalData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final query = await _firestore
          .collection('profissionais')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return ProfissionalModel.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting barber professional data: $e');
      return null;
    }
  }

  // Get barber's available services
  Future<List<ServiceModel>> getBarberServices() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final query = await _firestore
          .collection('servicos')
          .where('profissionalId', isEqualTo: user.uid)
          .where('ativo', isEqualTo: true)
          .get();

      return query.docs.map((doc) => ServiceModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error getting barber services: $e');
      return [];
    }
  }

  // Update appointment service
  Future<void> updateAppointmentService(String appointmentId, String newServiceName, double newPrice, int newDuration) async {
    try {
      await _firestore.collection('agendamentos').doc(appointmentId).update({
        'service': newServiceName,
        'price': newPrice,
        'duration': newDuration,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating appointment service: $e');
      rethrow;
    }
  }

  // Update appointment time
  Future<void> updateAppointmentTime(String appointmentId, DateTime newDateTime) async {
    try {
      await _firestore.collection('agendamentos').doc(appointmentId).update({
        'date': newDateTime.toIso8601String().split('T')[0], // Date part
        'time': '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}', // Time part
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating appointment time: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
