class AttendanceRecord {
  final String date;       // "2026-02-08"
  final String status;     // "PRESENT", "ABSENT"
  final String? checkIn;   // ISO String
  final String? checkOut;  // ISO String
  final double workHours;
  final bool isLate;

  AttendanceRecord({
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.workHours = 0.0,
    this.isLate = false,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: json['date'] ?? '',
      status: json['status'] ?? 'ABSENT',
      checkIn: json['check_in'],
      checkOut: json['check_out'],
      workHours: (json['work_hours'] as num?)?.toDouble() ?? 0.0,
      isLate: json['is_late'] ?? false,
    );
  }
}