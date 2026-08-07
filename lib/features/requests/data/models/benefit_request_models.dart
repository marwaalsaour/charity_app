import 'dart:io';

enum BenefitRequestKind { patient, orphan, school, university }

class BenefitRequestSubmitParams {
  final BenefitRequestKind kind;
  final String fullName;
  final String nationalId;
  final int governorateId;
  final int regionId;
  final String description;

  /// Patient only: true = use logged-in user contact.
  final bool isSelf;
  final String? phone;
  final String? email;
  final double? requiredAmount;

  /// School / university
  final String? academicGrade;
  final String? schoolName;
  final String? academicYear;
  final String? universityName;
  final String? supportType; // laptopsupport | tuitionassistance

  /// When true, donors may see the beneficiary real name on the case card.
  final bool showBeneficiaryName;

  /// Required files by kind
  final File? medicalReport;
  final File? nationalIdDocument;
  final File? familyBooklet;
  final File? fatherDeathCertificate;
  final File? familyBookPhoto;
  final File? universityIdPhoto;

  const BenefitRequestSubmitParams({
    required this.kind,
    required this.fullName,
    required this.nationalId,
    required this.governorateId,
    required this.regionId,
    required this.description,
    this.isSelf = true,
    this.phone,
    this.email,
    this.requiredAmount,
    this.academicGrade,
    this.schoolName,
    this.academicYear,
    this.universityName,
    this.supportType,
    this.showBeneficiaryName = false,
    this.medicalReport,
    this.nationalIdDocument,
    this.familyBooklet,
    this.fatherDeathCertificate,
    this.familyBookPhoto,
    this.universityIdPhoto,
  });
}

class BenefitRequestItem {
  final int id;
  final String requestType;
  final String status;
  final String? title;
  final String? description;
  final DateTime createdAt;
  final String? beneficiaryName;

  const BenefitRequestItem({
    required this.id,
    required this.requestType,
    required this.status,
    required this.createdAt,
    this.title,
    this.description,
    this.beneficiaryName,
  });

  bool get isApproved => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isPending => status == 'pending';

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) return title!.trim();
    if (beneficiaryName != null && beneficiaryName!.trim().isNotEmpty) {
      return beneficiaryName!.trim();
    }
    return requestType;
  }

  factory BenefitRequestItem.fromJson(Map<String, dynamic> json) {
    final beneficiary = json['beneficiary'];
    String? name;
    if (beneficiary is Map) {
      name = beneficiary['full_name']?.toString();
    }

    return BenefitRequestItem(
      id: _toInt(json['id']) ?? 0,
      requestType: json['request_type']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      createdAt: DateTime.tryParse(
            (json['created_at']?.toString() ?? '').replaceFirst(' ', 'T'),
          ) ??
          DateTime.now(),
      beneficiaryName: name,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'request_type': requestType,
        'status': status,
        'title': title,
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'beneficiary': {'full_name': beneficiaryName},
      };

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
