class CityModel {
  final int id;
  final String name;
  final int? governorateId;

  const CityModel({
    required this.id,
    required this.name,
    this.governorateId,
  });

  factory CityModel.fromJson(
    Map<String, dynamic> json, {
    int? governorateId,
  }) {
    return CityModel(
      id: _parseId(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      governorateId:
          _parseId(json['governorate_id']) ?? governorateId,
    );
  }

  static int? _parseId(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
