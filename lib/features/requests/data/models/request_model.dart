class RequestModel {
  final String? id;
  final String type; // 'medical', 'education', 'orphan'
  final String fullName;
  final String contact;
  final String address;
  final String description;
  final double? amount;

  // حقول خاصة بالتعليم
  final String? academicGrade;
  final String? schoolUniversityName;
  final int? educationLevel; // 0: University, 1: School
  final int? supportType;    // 0: Laptop, 1: Tuition

  // ملفات (Paths)
  final String? idPhotoPath;
  final String? documentPath1; // Medical report / Family book
  final String? documentPath2; // Death certificate (for orphans)

  RequestModel({
    this.id,
    required this.type,
    required this.fullName,
    required this.contact,
    required this.address,
    required this.description,
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
      'contact': contact,
      'address': address,
      'description': description,
      'amount': amount,
      'academic_grade': academicGrade,
      'institution_name': schoolUniversityName,
      'education_level': educationLevel,
      'support_type': supportType,
      // ملاحظة: الملفات ترفع عادة كـ MultipartFile وليس JSON عادي
    };
  }
}