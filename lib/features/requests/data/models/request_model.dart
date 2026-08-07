class RequestModel {
  final String? id;
  final String type; // medical, education, orphan
  final String fullName;
  final String nationalId;
  final String contact;
  final int? governorateId;
  final int? cityId;
  final String description;
  final double? amount;

  final String? academicGrade;
  final String? schoolUniversityName;
  final int? educationLevel; // 0: University, 1: School
  final int? supportType; // 0: Laptop, 1: Tuition

  final String? idPhotoPath;
  final String? documentPath1;
  final String? documentPath2;

  RequestModel({
    this.id,
    required this.type,
    required this.fullName,
    required this.nationalId,
    required this.contact,
    required this.description,
    this.governorateId,
    this.cityId,
    this.amount,
    this.academicGrade,
    this.schoolUniversityName,
    this.educationLevel,
    this.supportType,
    this.idPhotoPath,
    this.documentPath1,
    this.documentPath2,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'full_name': fullName,
      'national_id': nationalId,
      'contact': contact,
      'governorate_id': governorateId,
      'city_id': cityId,
      'description': description,
      'amount': amount,
      'academic_grade': academicGrade,
      'institution_name': schoolUniversityName,
      'education_level': educationLevel,
      'support_type': supportType,
    };
  }
}
