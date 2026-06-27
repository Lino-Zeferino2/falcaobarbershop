class ServiceModel {
  final String id;
  final String nome;
  final String descricao;
  final double preco;
  final int duracao;
  final String iconName;
  final bool ativo;
  final String profissionalId; // ID do profissional que oferece este serviço
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  ServiceModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.duracao,
    required this.iconName,
    required this.ativo,
    required this.profissionalId,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  // Converter para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'duracao': duracao,
      'iconName': iconName,
      'ativo': ativo,
      'profissionalId': profissionalId,
      'criadoEm': criadoEm.toIso8601String(),
      'atualizadoEm': atualizadoEm.toIso8601String(),
    };
  }

  // Criar ServiceModel a partir de Map (do Firestore)
  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
      preco: (map['preco'] ?? 0.0).toDouble(),
      duracao: (map['duracao'] ?? 0).toInt(),
      iconName: map['iconName'] ?? 'content_cut',
      ativo: map['ativo'] ?? true,
      profissionalId: map['profissionalId'] ?? '',
      criadoEm: DateTime.parse(map['criadoEm'] ?? DateTime.now().toIso8601String()),
      atualizadoEm: DateTime.parse(map['atualizadoEm'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Criar cópia com alterações
  ServiceModel copyWith({
    String? id,
    String? nome,
    String? descricao,
    double? preco,
    int? duracao,
    String? iconName,
    bool? ativo,
    String? profissionalId,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      preco: preco ?? this.preco,
      duracao: duracao ?? this.duracao,
      iconName: iconName ?? this.iconName,
      ativo: ativo ?? this.ativo,
      profissionalId: profissionalId ?? this.profissionalId,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
