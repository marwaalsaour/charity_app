enum UserRole {
  donor,
  beneficiary;

  String get homeRoute => switch (this) {
    UserRole.donor => '/donor/home',
    UserRole.beneficiary => '/beneficiary/home',
  };

  String get loginRoute => switch (this) {
    UserRole.donor => '/login/donor',
    UserRole.beneficiary => '/login/beneficiary',
  };

  static UserRole? fromString(String? value) {
    return switch (value) {
      'donor' => UserRole.donor,
      'beneficiary' => UserRole.beneficiary,
      _ => null,
    };
  }
}
