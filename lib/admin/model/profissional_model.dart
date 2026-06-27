class ProfissionalModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String barbeariaId;
  final String? especialidade;
  final List<String> diasAtendimento; // Mantido para compatibilidade
  final Map<String, Map<String, String>> turnos; // Mantido para compatibilidade
  final Map<String, Map<String, dynamic>?>? horariosPorDia; // Novo campo: chave = dia da semana ou data específica, valor = turnos ou null (fechado)
  final int intervaloMinutos;
  final String? fotoUrl;
  final String? descricao;
  final bool disponivel;
  final DateTime createdAt;

  ProfissionalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.barbeariaId,
    this.especialidade,
    required this.diasAtendimento,
    required this.turnos,
    this.horariosPorDia,
    required this.intervaloMinutos,
    this.fotoUrl,
    this.descricao,
    required this.disponivel,
    required this.createdAt,
  });

  // Converter para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'barbeariaId': barbeariaId,
      'especialidade': especialidade,
      'diasAtendimento': diasAtendimento,
      'turnos': turnos,
      'horariosPorDia': horariosPorDia,
      'intervaloMinutos': intervaloMinutos,
      'fotoUrl': fotoUrl,
      'descricao': descricao,
      'disponivel': disponivel,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Criar ProfissionalModel a partir de Map (do Firestore)
  factory ProfissionalModel.fromMap(Map<String, dynamic> map, String id) {
    return ProfissionalModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      barbeariaId: map['barbeariaId'] ?? '',
      especialidade: map['especialidade'],
      diasAtendimento: List<String>.from(map['diasAtendimento'] ?? []),
      turnos: (map['turnos'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, Map<String, String>.from(value as Map)),
      ) ?? {},
      horariosPorDia: (map['horariosPorDia'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>?),
      ),
      intervaloMinutos: map['intervaloMinutos'] ?? 30,
      fotoUrl: map['fotoUrl'],
      descricao: map['descricao'],
      disponivel: map['disponivel'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Criar cópia com alterações
  ProfissionalModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? barbeariaId,
    String? especialidade,
    List<String>? diasAtendimento,
    Map<String, Map<String, String>>? turnos,
    Map<String, Map<String, dynamic>?>? horariosPorDia,
    int? intervaloMinutos,
    String? fotoUrl,
    String? descricao,
    bool? disponivel,
    DateTime? createdAt,
  }) {
    return ProfissionalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      barbeariaId: barbeariaId ?? this.barbeariaId,
      especialidade: especialidade ?? this.especialidade,
      diasAtendimento: diasAtendimento ?? this.diasAtendimento,
      turnos: turnos ?? this.turnos,
      horariosPorDia: horariosPorDia ?? this.horariosPorDia,
      intervaloMinutos: intervaloMinutos ?? this.intervaloMinutos,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      descricao: descricao ?? this.descricao,
      disponivel: disponivel ?? this.disponivel,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
