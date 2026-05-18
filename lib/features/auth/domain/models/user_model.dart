class UserModel {
  final String uid;
  final String name;
  final String email;
  final String type; // 'admin' | 'pediatra' | 'usuario'
  final String estado;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.type,
    required this.estado,
  });

  factory UserModel.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      type: _normalizeType(data['type']),
      estado: (data['estado'] ?? '').toString().toLowerCase().trim(),
    );
  }

  static String _normalizeType(dynamic raw) {
    final value = (raw ?? '')
        .toString()
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll(RegExp(r'[^a-z]'), '');

    if (value == 'admin') return 'admin';
    if (value.startsWith('pediatra')) return 'pediatra';
    return 'usuario';
  }

  bool get isEnabled => estado == 'habilitado';
  bool get isPending => estado == 'pendiente';
}

class RegisterData {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String address;
  final DateTime birthDate;
  final bool isPediatrician;

  // Campos exclusivos del pediatra
  final String? country;
  final String? workAddress;
  final DateTime? startDate;
  final String? polizaUrl;
  final String? tarjetaProfesionalUrl;
  final String? documentoIdentidadFrenteUrl;
  final String? documentoIdentidadReversoUrl;

  const RegisterData({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.address,
    required this.birthDate,
    required this.isPediatrician,
    this.country,
    this.workAddress,
    this.startDate,
    this.polizaUrl,
    this.tarjetaProfesionalUrl,
    this.documentoIdentidadFrenteUrl,
    this.documentoIdentidadReversoUrl,
  });
}
