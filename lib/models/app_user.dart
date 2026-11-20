enum UserRole {
  admin,
  kasir;

  static UserRole fromValue(String? value) {
    return value?.toLowerCase() == 'admin' ? UserRole.admin : UserRole.kasir;
  }

  String get value => name;

  String get label => this == UserRole.admin ? 'Admin' : 'Kasir';

  String get description => this == UserRole.admin
      ? 'Kelola menu, pantau penjualan, dan lihat seluruh transaksi.'
      : 'Proses pesanan pelanggan dan terima pembayaran.';
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({String? name, String? email, UserRole? role}) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'role': role.value,
  };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? (map['name'] as String).trim()
          : (map['email'] as String?)?.split('@').first ?? 'Pengguna',
      email: (map['email'] as String?) ?? '',
      role: UserRole.fromValue(map['role'] as String?),
    );
  }
}
