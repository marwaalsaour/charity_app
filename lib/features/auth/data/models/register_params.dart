import 'dart:io';

import '../../../../core/auth/user_role.dart';

class RegisterParams {
  const RegisterParams({
    required this.firstName,
    required this.lastName,
    required this.password,
    required this.passwordConfirmation,
    required this.address,
    required this.dateOfBirth,
    required this.profileImage,
    required this.role,
    this.phone,
    this.email,
    this.nationalIdImage,
    this.passportImage,
  });

  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String password;
  final String passwordConfirmation;
  final String address;
  final DateTime dateOfBirth;
  final File profileImage;
  final File? nationalIdImage;
  final File? passportImage;
  final UserRole role;

  String get userCategory =>
      role == UserRole.beneficiary ? 'beneficiary' : 'public';

  String get dateOfBirthApi =>
      '${dateOfBirth.year.toString().padLeft(4, '0')}-'
      '${dateOfBirth.month.toString().padLeft(2, '0')}-'
      '${dateOfBirth.day.toString().padLeft(2, '0')}';
}
