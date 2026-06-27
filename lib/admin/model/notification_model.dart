import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/appointment_model.dart';

class NotificationModel {
  final String id;
  final String titulo;
  final String mensagem;
  final bool lida;
  final DateTime createdAt;
  final AppointmentModel? appointment; // Associated appointment for appointment alerts

  NotificationModel({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.lida,
    required this.createdAt,
    this.appointment,
  });

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      titulo: map['titulo'] ?? '',
      mensagem: map['mensagem'] ?? '',
      lida: map['lida'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appointment: null, // Will be set when creating appointment alerts
    );
  }

  // Factory for creating appointment alert notifications
  factory NotificationModel.fromAppointment(AppointmentModel appointment, String type) {
    String titulo;
    String mensagem;

    switch (type) {
      case 'pending':
        titulo = 'Novo Agendamento Pendente';
        mensagem = '${appointment.clientName} agendou ${appointment.serviceName} para ${appointment.dateTime.day}/${appointment.dateTime.month} às ${appointment.dateTime.hour}:${appointment.dateTime.minute.toString().padLeft(2, '0')}';
        break;
      case 'confirmed':
        titulo = 'Agendamento Confirmado';
        mensagem = 'Agendamento de ${appointment.clientName} foi confirmado';
        break;
      case 'cancelled':
        titulo = 'Agendamento Cancelado';
        mensagem = 'Agendamento de ${appointment.clientName} foi cancelado';
        break;
      case 'completed':
        titulo = 'Agendamento Concluído';
        mensagem = 'Agendamento de ${appointment.clientName} foi marcado como concluído';
        break;
      default:
        titulo = 'Alerta de Agendamento';
        mensagem = 'Novo alerta para agendamento';
    }

    return NotificationModel(
      id: appointment.id,
      titulo: titulo,
      mensagem: mensagem,
      lida: false,
      createdAt: appointment.createdAt,
      appointment: appointment,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'mensagem': mensagem,
      'lida': lida,
      'createdAt': createdAt,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? titulo,
    String? mensagem,
    bool? lida,
    DateTime? createdAt,
    AppointmentModel? appointment,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      mensagem: mensagem ?? this.mensagem,
      lida: lida ?? this.lida,
      createdAt: createdAt ?? this.createdAt,
      appointment: appointment ?? this.appointment,
    );
  }
}
