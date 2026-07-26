class Employee {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phoneNumber;
  final DateTime createdAt;
  final bool isActive;
  final String? profileImageUrl;
  final String officeName; // <--- NEW FIELD

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.createdAt,
    required this.isActive,
    this.profileImageUrl,
    required this.officeName, // <--- Required in constructor
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['employee_id'] ?? 'Unknown ID',
      name: json['full_name'] ?? 'No Name',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Employee',
      phoneNumber: json['phone'] ?? 'N/A',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isActive: json['is_active'] ?? true,
      profileImageUrl: json['profile_image_url'],

      // <--- NEW MAPPING
      // Ensure your Firestore document actually has this key
      officeName: json['office_name'] ?? 'Remote / N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': id,
      'full_name': name,
      'email': email,
      'role': role,
      'phone': phoneNumber,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
      'profile_image_url': profileImageUrl,
      'office_location': officeName, // <--- Include in export
    };
  }
}