class OfficeModel {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double radius;
  final String checkInStart;
  final String checkInEnd;
  final String checkOutStart;
  final String checkOutEnd;

  OfficeModel({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.checkInStart,
    required this.checkInEnd,
    required this.checkOutStart,
    required this.checkOutEnd,
  });

  factory OfficeModel.fromJson(Map<String, dynamic> json) {
    return OfficeModel(
      name: json['name'] ?? 'Unknown Office',
      address: json['address'] ?? 'No Address Available', // Fallback ensures no crash
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0, // Safety cast
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      radius: (json['radius'] as num?)?.toDouble() ?? 100.0,
      checkInStart: json['check_in_start'] ?? '09:00',
      checkInEnd: json['check_in_end'] ?? '10:00',
      checkOutStart: json['check_out_start'] ?? '17:00',
      checkOutEnd: json['check_out_end'] ?? '18:00',
    );
  }
}