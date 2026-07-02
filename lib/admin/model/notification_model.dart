import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/appointment_model.dart';

class NotificationModel {
  final String id;
  final String titulo;
  final String mensagem;
  final bool lida;
  final DateTime createdAt;
  final String tipo; // 👈 NOVO campo — usado para escolher o ícone na UI
  final AppointmentModel? appointment;

  NotificationModel({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.lida,
    required this.createdAt,
    this.tipo = 'default', // 👈 NOVO, com valor por omissão seguro
    this.appointment,
  });

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      titulo: map['titulo'] ?? '',
      mensagem: map['mensagem'] ?? '',
      lida: map['lida'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tipo: map['tipo'] ?? 'default', // 👈 NOVO
      appointment: null,
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
      tipo: type, // 👈 NOVO — agora o "type" recebido é guardado, não descartado
      appointment: appointment,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'mensagem': mensagem,
      'lida': lida,
      'createdAt': createdAt,
      'tipo': tipo, // 👈 NOVO
    };
  }

  NotificationModel copyWith({
    String? id,
    String? titulo,
    String? mensagem,
    bool? lida,
    DateTime? createdAt,
    String? tipo, // 👈 NOVO
    AppointmentModel? appointment,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      mensagem: mensagem ?? this.mensagem,
      lida: lida ?? this.lida,
      createdAt: createdAt ?? this.createdAt,
      tipo: tipo ?? this.tipo, // 👈 NOVO
      appointment: appointment ?? this.appointment,
    );
  }
}