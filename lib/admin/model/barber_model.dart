class BarberModel {
  final String id;
  final String name;
  final String specialty;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final int weeklyAppointments; // Número de agendamentos na semana

  BarberModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
    this.weeklyAppointments = 0,
  });

  // Converter para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'weeklyAppointments': weeklyAppointments,
    };
  }

  // Criar BarberModel a partir de Map (do Firestore)
  factory BarberModel.fromMap(Map<String, dynamic> map) {
    return BarberModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      specialty: map['specialty'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      weeklyAppointments: map['weeklyAppointments'] ?? 0,
    );
  }

  // Criar cópia com alterações
  BarberModel copyWith({
    String? id,
    String? name,
    String? specialty,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    int? weeklyAppointments,
  }) {
    return BarberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      weeklyAppointments: weeklyAppointments ?? this.weeklyAppointments,
    );
  }
}
