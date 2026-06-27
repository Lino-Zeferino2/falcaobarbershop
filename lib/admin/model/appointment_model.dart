class AppointmentModel {
  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String barberId;
  final String barberName;
  final String serviceName;
  final double price;
  final int duration; // Duração em minutos
  final DateTime dateTime;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime? concludedAt; // Data/hora quando foi concluído (automaticamente ou manualmente)
  final bool reminderSent; // Se o lembrete de 35min foi enviado

  AppointmentModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.barberId,
    required this.barberName,
    required this.serviceName,
    required this.price,
    required this.duration,
    required this.dateTime,
    required this.status,
    required this.createdAt,
    this.concludedAt,
    this.reminderSent = false,
  });

  // Converter para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'barberId': barberId,
      'barberName': barberName,
      'serviceName': serviceName,
      'price': price,
      'duration': duration,
      'dateTime': dateTime.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'concludedAt': concludedAt?.toIso8601String(),
    };
  }

  // Criar AppointmentModel a partir de Map (do Firestore)
  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientPhone: map['clientPhone'] ?? '',
      barberId: map['barberId'] ?? '',
      barberName: map['barberName'] ?? '',
      serviceName: map['serviceName'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      duration: (map['duration'] ?? 0).toInt(),
      dateTime: DateTime.parse(map['dateTime'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      concludedAt: map['concludedAt'] != null ? DateTime.parse(map['concludedAt']) : null,
      reminderSent: map['reminderSent'] ?? false,
    );
  }

  // Criar cópia com alterações
  AppointmentModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientPhone,
    String? barberId,
    String? barberName,
    String? serviceName,
    double? price,
    int? duration,
    DateTime? dateTime,
    String? status,
    DateTime? createdAt,
    DateTime? concludedAt,
    bool? reminderSent,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      barberId: barberId ?? this.barberId,
      barberName: barberName ?? this.barberName,
      serviceName: serviceName ?? this.serviceName,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      concludedAt: concludedAt ?? this.concludedAt,
      reminderSent: reminderSent ?? this.reminderSent,
    );
  }
}
