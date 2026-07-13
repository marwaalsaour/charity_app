class UserProfileModel {
  final String firstName;
  final String lastName;
  final String phone;
  final String address;
  final String? imagePath;
  final int memberSinceYear;

  const UserProfileModel({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.address,
    this.imagePath,
    this.memberSinceYear = 2022,
  });

  bool get hasName => firstName.trim().isNotEmpty || lastName.trim().isNotEmpty;

  String get fullName => '${firstName.trim()} ${lastName.trim()}'.trim();

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      imagePath: json['image_path'] as String?,
      memberSinceYear: json['member_since_year'] as int? ?? 2022,
    );
  }

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'phone': phone,
    'address': address,
    'image_path': imagePath,
    'member_since_year': memberSinceYear,
  };

  UserProfileModel copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? imagePath,
    bool clearImage = false,
    int? memberSinceYear,
  }) {
    return UserProfileModel(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      memberSinceYear: memberSinceYear ?? this.memberSinceYear,
    );
  }
}
