import 'enums.dart';

class Driver {
  final String id;
  final String staffNumber;
  final String name;
  final String phone;
  final String email;
  final String photoUrl;
  final String licenseNumber;
  final String licenseClass;
  final String licenseExpiry;
  final DriverStatus status;
  final int performanceScore; // 0-100
  final int riskScore; // 0-100

  const Driver({
    required this.id,
    required this.staffNumber,
    required this.name,
    required this.phone,
    required this.email,
    required this.photoUrl,
    required this.licenseNumber,
    required this.licenseClass,
    required this.licenseExpiry,
    required this.status,
    required this.performanceScore,
    required this.riskScore,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
        id: json['id'],
        staffNumber: json['staffNumber'],
        name: json['name'],
        phone: json['phone'],
        email: json['email'],
        photoUrl: json['photoUrl'],
        licenseNumber: json['licenseNumber'],
        licenseClass: json['licenseClass'],
        licenseExpiry: json['licenseExpiry'],
        status: DriverStatus.fromLabel(json['status']),
        performanceScore: json['performanceScore'],
        riskScore: json['riskScore'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'staffNumber': staffNumber,
        'name': name,
        'phone': phone,
        'email': email,
        'photoUrl': photoUrl,
        'licenseNumber': licenseNumber,
        'licenseClass': licenseClass,
        'licenseExpiry': licenseExpiry,
        'status': status.label,
        'performanceScore': performanceScore,
        'riskScore': riskScore,
      };
}
