class BarbeariaModel {
  final String id;
  final String name;
  final String address;
  final String daysHours;
  final String phone;
  final bool isActive;

  BarbeariaModel({
    required this.id,
    required this.name,
    required this.address,
    required this.daysHours,
    required this.phone,
    required this.isActive,
  });

  factory BarbeariaModel.fromMap(Map<String, dynamic> map, String id) {
    return BarbeariaModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      daysHours: map['daysHours'] ?? '',
      phone: map['phone'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'daysHours': daysHours,
      'phone': phone,
      'isActive': isActive,
    };
  }
}
