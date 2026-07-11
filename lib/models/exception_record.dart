import 'enums.dart';

/// Named ExceptionRecord (not Exception) to avoid clashing with Dart's built-in Exception type.
class ExceptionRecord {
  final String id;
  final String type; // Fuel | Maintenance | Trip | Manifest | Tamper | Policy
  final ExceptionSeverity severity;
  final String title;
  final String description;
  final String vehicleId;
  final String? driverId;
  final String timestamp;
  final String status; // Open | In Investigation | Resolved
  final String? resolutionNotes;
  final String? resolvedBy;

  const ExceptionRecord({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.vehicleId,
    this.driverId,
    required this.timestamp,
    required this.status,
    this.resolutionNotes,
    this.resolvedBy,
  });

  ExceptionRecord copyWith({
    String? status,
    String? resolutionNotes,
    String? resolvedBy,
  }) {
    return ExceptionRecord(
      id: id,
      type: type,
      severity: severity,
      title: title,
      description: description,
      vehicleId: vehicleId,
      driverId: driverId,
      timestamp: timestamp,
      status: status ?? this.status,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      resolvedBy: resolvedBy ?? this.resolvedBy,
    );
  }

  factory ExceptionRecord.fromJson(Map<String, dynamic> json) => ExceptionRecord(
        id: json['id'],
        type: json['type'],
        severity: ExceptionSeverity.fromLabel(json['severity']),
        title: json['title'],
        description: json['description'],
        vehicleId: json['vehicleId'],
        driverId: json['driverId'],
        timestamp: json['timestamp'],
        status: json['status'],
        resolutionNotes: json['resolutionNotes'],
        resolvedBy: json['resolvedBy'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'severity': severity.label,
        'title': title,
        'description': description,
        'vehicleId': vehicleId,
        'driverId': driverId,
        'timestamp': timestamp,
        'status': status,
        'resolutionNotes': resolutionNotes,
        'resolvedBy': resolvedBy,
      };
}
