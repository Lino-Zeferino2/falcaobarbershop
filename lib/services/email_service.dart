import 'package:cloud_firestore/cloud_firestore.dart';
import '../firestore_instance.dart';

class EmailService {
  final FirebaseFirestore _firestore = firestore;

  /// Envia email criando documento na coleção 'mail'
  Future<bool> sendEmail({
    required String template,
    required String toEmail,
    required Map<String, dynamic> templateParams,
  }) async {
    try {
      // Combinar to_email com os outros parâmetros
      final emailData = {
        ...templateParams,
        'to_email': toEmail,
        'template': template,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      print('📧 ENVIANDO EMAIL - Template: $template');
      print('📧 Para: $toEmail');
      print('📧 Dados: $emailData');

      await _firestore.collection('mail').add(emailData);
      print('✅ Documento de email criado com sucesso para template: $template');
      return true;
    } catch (e) {
      print('❌ Erro ao criar documento de email: $e');
      return false;
    }
  }

  /// Envia email de agendamento recebido
  Future<bool> sendBookingReceivedEmail({
    required String service,
    required String professional,
    required String date,
    required String time,
    required String barbearia,
    required String name,
    required String phone,
    required String email,
    required double price,
  }) async {
    return await sendEmail(
      template: 'booking_received',
      toEmail: email,
      templateParams: {
        'service': service,
        'professional': professional,
        'date': date,
        'time': time,
        'barbearia': barbearia,
        'name': name,
        'phone': phone,
        'email': email,
        'price': price.toStringAsFixed(2),
      },
    );
  }

  /// Envia email de agendamento confirmado
  Future<bool> sendBookingConfirmedEmail({
    required String service,
    required String professional,
    required String date,
    required String time,
    required String barbearia,
    required String name,
    required String phone,
    required String email,
    required double price,
  }) async {
    return await sendEmail(
      template: 'booking_confirmed',
      toEmail: email,
      templateParams: {
        'service': service,
        'professional': professional,
        'date': date,
        'time': time,
        'barbearia': barbearia,
        'name': name,
        'phone': phone,
        'email': email,
        'price': price.toStringAsFixed(2),
      },
    );
  }

  /// Envia email de agendamento cancelado
  Future<bool> sendBookingCancelledEmail({
    required String service,
    required String professional,
    required String date,
    required String time,
    required String barbearia,
    required String name,
    required String phone,
    required String email,
    required double price,
  }) async {
    return await sendEmail(
      template: 'booking_cancelled',
      toEmail: email,
      templateParams: {
        'service': service,
        'professional': professional,
        'date': date,
        'time': time,
        'barbearia': barbearia,
        'name': name,
        'phone': phone,
        'email': email,
        'price': price.toStringAsFixed(2),
      },
    );
  }

  /// Envia email solicitando avaliação
  Future<bool> sendReviewRequestEmail({
    required String service,
    required String professional,
    required String date,
    required String time,
    required String barbearia,
    required String name,
    required String phone,
    required String email,
    String? reviewUrl,
  }) async {
    final templateParams = {
      'service': service,
      'professional': professional,
      'date': date,
      'time': time,
      'barbearia': barbearia,
      'name': name,
      'phone': phone,
      'email': email,
    };

    if (reviewUrl != null) {
      templateParams['review_url'] = reviewUrl;
    }

    return await sendEmail(
      template: 'review_request',
      toEmail: email,
      templateParams: templateParams,
    );
  }

  /// Envia email de atualização de agendamento
  Future<bool> sendAppointmentUpdateEmail({
    required String service,
    required String professional,
    required String date,
    required String time,
    required String barbearia,
    required String name,
    required String phone,
    required String email,
    required String updateType, // 'service' or 'time'
  }) async {
    return await sendEmail(
      template: 'appointment_update',
      toEmail: email,
      templateParams: {
        'service': service,
        'professional': professional,
        'date': date,
        'time': time,
        'barbearia': barbearia,
        'name': name,
        'phone': phone,
        'email': email,
        'update_type': updateType,
      },
    );
  }

  /// Envia email de notificação de novo agendamento para o admin
  Future<bool> sendNewAppointmentNotificationToAdmin({
    required String service,
    required String professional,
    required String date,
    required String time,
    required String barbearia,
    required String clientName,
    required String clientPhone,
    required String clientEmail,
    required double price,
  }) async {
    return await sendEmail(
      template: 'admin_booking_notification',
      toEmail: 'falcaobarbershop00@gmail.com',
      templateParams: {
        'service': service,
        'professional': professional,
        'date': date,
        'time': time,
        'barbearia': barbearia,
        'name': clientName,
        'phone': clientPhone,
        'email': clientEmail,
        'price': price.toStringAsFixed(2),
      },
    );
  }
}
