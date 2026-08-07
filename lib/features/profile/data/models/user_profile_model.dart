class UserProfileModel {
  final int? id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String address;
  final String? imagePath;
  final int memberSinceYear;
  final Map<String, double> balances;

  const UserProfileModel({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    required this.address,
    this.imagePath,
    this.memberSinceYear = 2022,
    this.balances = const {},
  });

  bool get hasName => firstName.trim().isNotEmpty || lastName.trim().isNotEmpty;

  String get fullName => '${firstName.trim()} ${lastName.trim()}'.trim();

  /// Prefer USD, otherwise first positive balance, otherwise USD 0.
  ({double amount, String currency}) get primaryWallet {
    final usd = balances['USD'];
    if (usd != null) return (amount: usd, currency: 'USD');

    for (final entry in balances.entries) {
      if (entry.value > 0) {
        return (amount: entry.value, currency: entry.key);
      }
    }

    if (balances.isNotEmpty) {
      final first = balances.entries.first;
      return (amount: first.value, currency: first.key);
    }

    return (amount: 0, currency: 'USD');
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: _toInt(json['id']),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      address: json['address'] as String? ?? '',
      imagePath: json['image_path'] as String?,
      memberSinceYear: json['member_since_year'] as int? ?? 2022,
      balances: _parseBalances(json['balances']),
    );
  }

  /// Maps a Laravel `user` object from /userprofile.
  factory UserProfileModel.fromApiUser(
    Map<dynamic, dynamic> user, {
    String? imageUrl,
  }) {
    final createdAt = user['created_at']?.toString();
    final memberYear = createdAt != null && createdAt.length >= 4
        ? int.tryParse(createdAt.substring(0, 4)) ?? DateTime.now().year
        : DateTime.now().year;

    return UserProfileModel(
      id: _toInt(user['id']),
      firstName: user['first_name']?.toString() ?? '',
      lastName: user['last_name']?.toString() ?? '',
      phone: user['phone']?.toString() ?? '',
      email: user['email']?.toString(),
      address: user['address']?.toString() ?? '',
      imagePath: imageUrl,
      memberSinceYear: memberYear,
      balances: _parseBalances(user['balances']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'email': email,
        'address': address,
        'image_path': imagePath,
        'member_since_year': memberSinceYear,
        'balances': balances,
      };

  UserProfileModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? address,
    String? imagePath,
    bool clearImage = false,
    int? memberSinceYear,
    Map<String, double>? balances,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      memberSinceYear: memberSinceYear ?? this.memberSinceYear,
      balances: balances ?? this.balances,
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static Map<String, double> _parseBalances(dynamic raw) {
    if (raw is! Map) return {};
    final result = <String, double>{};
    raw.forEach((key, value) {
      if (key == null) return;
      final amount = value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '');
      if (amount != null) result[key.toString()] = amount;
    });
    return result;
  }
}
