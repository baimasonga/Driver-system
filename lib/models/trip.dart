import 'enums.dart';

class Trip {
  final String id;
  final String tripRequestNumber;
  final String vehicleId;
  final String driverId;
  final String department;
  final List<String> passengers;
  final String? cargoNotes;
  final String purpose;
  final String pickupPoint;
  final String destination;
  final TripStatus status;

  final String requestedAt;
  final String? approvedAt;
  final String? startedAt;
  final String? endedAt;
  final String? overdueThresholdAt;

  final double? signOutOdometer;
  final double? signOutFuelLevel;
  final String? signOutOfficerName;
  final String? signOutTime;

  final double? signInOdometer;
  final double? signInFuelLevel;
  final String? signInOfficerName;
  final String? signInTime;

  final double? gpsDistanceKm;
  final bool? routeDeviationFlagged;

  const Trip({
    required this.id,
    required this.tripRequestNumber,
    required this.vehicleId,
    required this.driverId,
    required this.department,
    required this.passengers,
    this.cargoNotes,
    required this.purpose,
    required this.pickupPoint,
    required this.destination,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.startedAt,
    this.endedAt,
    this.overdueThresholdAt,
    this.signOutOdometer,
    this.signOutFuelLevel,
    this.signOutOfficerName,
    this.signOutTime,
    this.signInOdometer,
    this.signInFuelLevel,
    this.signInOfficerName,
    this.signInTime,
    this.gpsDistanceKm,
    this.routeDeviationFlagged,
  });

  Trip copyWith({
    TripStatus? status,
    String? approvedAt,
    String? startedAt,
    String? endedAt,
    double? signOutOdometer,
    double? signOutFuelLevel,
    String? signOutOfficerName,
    String? signOutTime,
    double? signInOdometer,
    double? signInFuelLevel,
    String? signInOfficerName,
    String? signInTime,
    double? gpsDistanceKm,
    bool? routeDeviationFlagged,
  }) {
    return Trip(
      id: id,
      tripRequestNumber: tripRequestNumber,
      vehicleId: vehicleId,
      driverId: driverId,
      department: department,
      passengers: passengers,
      cargoNotes: cargoNotes,
      purpose: purpose,
      pickupPoint: pickupPoint,
      destination: destination,
      status: status ?? this.status,
      requestedAt: requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      overdueThresholdAt: overdueThresholdAt,
      signOutOdometer: signOutOdometer ?? this.signOutOdometer,
      signOutFuelLevel: signOutFuelLevel ?? this.signOutFuelLevel,
      signOutOfficerName: signOutOfficerName ?? this.signOutOfficerName,
      signOutTime: signOutTime ?? this.signOutTime,
      signInOdometer: signInOdometer ?? this.signInOdometer,
      signInFuelLevel: signInFuelLevel ?? this.signInFuelLevel,
      signInOfficerName: signInOfficerName ?? this.signInOfficerName,
      signInTime: signInTime ?? this.signInTime,
      gpsDistanceKm: gpsDistanceKm ?? this.gpsDistanceKm,
      routeDeviationFlagged: routeDeviationFlagged ?? this.routeDeviationFlagged,
    );
  }

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'],
        tripRequestNumber: json['tripRequestNumber'],
        vehicleId: json['vehicleId'],
        driverId: json['driverId'],
        department: json['department'],
        passengers: List<String>.from(json['passengers'] ?? []),
        cargoNotes: json['cargoNotes'],
        purpose: json['purpose'],
        pickupPoint: json['pickupPoint'],
        destination: json['destination'],
        status: TripStatus.fromLabel(json['status']),
        requestedAt: json['requestedAt'],
        approvedAt: json['approvedAt'],
        startedAt: json['startedAt'],
        endedAt: json['endedAt'],
        overdueThresholdAt: json['overdueThresholdAt'],
        signOutOdometer: (json['signOutOdometer'] as num?)?.toDouble(),
        signOutFuelLevel: (json['signOutFuelLevel'] as num?)?.toDouble(),
        signOutOfficerName: json['signOutOfficerName'],
        signOutTime: json['signOutTime'],
        signInOdometer: (json['signInOdometer'] as num?)?.toDouble(),
        signInFuelLevel: (json['signInFuelLevel'] as num?)?.toDouble(),
        signInOfficerName: json['signInOfficerName'],
        signInTime: json['signInTime'],
        gpsDistanceKm: (json['gpsDistanceKm'] as num?)?.toDouble(),
        routeDeviationFlagged: json['routeDeviationFlagged'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripRequestNumber': tripRequestNumber,
        'vehicleId': vehicleId,
        'driverId': driverId,
        'department': department,
        'passengers': passengers,
        'cargoNotes': cargoNotes,
        'purpose': purpose,
        'pickupPoint': pickupPoint,
        'destination': destination,
        'status': status.label,
        'requestedAt': requestedAt,
        'approvedAt': approvedAt,
        'startedAt': startedAt,
        'endedAt': endedAt,
        'overdueThresholdAt': overdueThresholdAt,
        'signOutOdometer': signOutOdometer,
        'signOutFuelLevel': signOutFuelLevel,
        'signOutOfficerName': signOutOfficerName,
        'signOutTime': signOutTime,
        'signInOdometer': signInOdometer,
        'signInFuelLevel': signInFuelLevel,
        'signInOfficerName': signInOfficerName,
        'signInTime': signInTime,
        'gpsDistanceKm': gpsDistanceKm,
        'routeDeviationFlagged': routeDeviationFlagged,
      };
}
