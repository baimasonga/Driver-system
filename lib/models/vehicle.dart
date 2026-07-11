import 'enums.dart';

class GpsLocation {
  final double lat;
  final double lng;
  final String address;

  const GpsLocation({required this.lat, required this.lng, required this.address});

  factory GpsLocation.fromJson(Map<String, dynamic> json) => GpsLocation(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        address: json['address'] as String,
      );

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng, 'address': address};
}

class Vehicle {
  final String id;
  final String registrationNumber;
  final String make;
  final String model;
  final int year;
  final String type;
  final String fuelType; // Petrol | Diesel
  final double tankCapacity;
  final double expectedFuelConsumption; // km per liter
  final double currentOdometer;
  final VehicleStatus status;
  final String assignedDriverId;
  final String assignedDepartment;
  final String insuranceExpiry;
  final String roadworthinessExpiry;
  final String gpsTrackerId;
  final TrackerStatus trackerStatus;
  final GpsLocation lastGpsLocation;
  final String lastGpsUpdateTime;
  final double monthlyFuelLimit;
  final double currentMonthFuelUsed;

  const Vehicle({
    required this.id,
    required this.registrationNumber,
    required this.make,
    required this.model,
    required this.year,
    required this.type,
    required this.fuelType,
    required this.tankCapacity,
    required this.expectedFuelConsumption,
    required this.currentOdometer,
    required this.status,
    required this.assignedDriverId,
    required this.assignedDepartment,
    required this.insuranceExpiry,
    required this.roadworthinessExpiry,
    required this.gpsTrackerId,
    required this.trackerStatus,
    required this.lastGpsLocation,
    required this.lastGpsUpdateTime,
    required this.monthlyFuelLimit,
    required this.currentMonthFuelUsed,
  });

  Vehicle copyWith({
    double? currentOdometer,
    VehicleStatus? status,
    TrackerStatus? trackerStatus,
    GpsLocation? lastGpsLocation,
    String? lastGpsUpdateTime,
    double? currentMonthFuelUsed,
  }) {
    return Vehicle(
      id: id,
      registrationNumber: registrationNumber,
      make: make,
      model: model,
      year: year,
      type: type,
      fuelType: fuelType,
      tankCapacity: tankCapacity,
      expectedFuelConsumption: expectedFuelConsumption,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      status: status ?? this.status,
      assignedDriverId: assignedDriverId,
      assignedDepartment: assignedDepartment,
      insuranceExpiry: insuranceExpiry,
      roadworthinessExpiry: roadworthinessExpiry,
      gpsTrackerId: gpsTrackerId,
      trackerStatus: trackerStatus ?? this.trackerStatus,
      lastGpsLocation: lastGpsLocation ?? this.lastGpsLocation,
      lastGpsUpdateTime: lastGpsUpdateTime ?? this.lastGpsUpdateTime,
      monthlyFuelLimit: monthlyFuelLimit,
      currentMonthFuelUsed: currentMonthFuelUsed ?? this.currentMonthFuelUsed,
    );
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'],
        registrationNumber: json['registrationNumber'],
        make: json['make'],
        model: json['model'],
        year: json['year'],
        type: json['type'],
        fuelType: json['fuelType'],
        tankCapacity: (json['tankCapacity'] as num).toDouble(),
        expectedFuelConsumption: (json['expectedFuelConsumption'] as num).toDouble(),
        currentOdometer: (json['currentOdometer'] as num).toDouble(),
        status: VehicleStatus.fromLabel(json['status']),
        assignedDriverId: json['assignedDriverId'],
        assignedDepartment: json['assignedDepartment'],
        insuranceExpiry: json['insuranceExpiry'],
        roadworthinessExpiry: json['roadworthinessExpiry'],
        gpsTrackerId: json['gpsTrackerId'],
        trackerStatus: TrackerStatus.fromLabel(json['trackerStatus']),
        lastGpsLocation: GpsLocation.fromJson(json['lastGpsLocation']),
        lastGpsUpdateTime: json['lastGpsUpdateTime'],
        monthlyFuelLimit: (json['monthlyFuelLimit'] as num).toDouble(),
        currentMonthFuelUsed: (json['currentMonthFuelUsed'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'registrationNumber': registrationNumber,
        'make': make,
        'model': model,
        'year': year,
        'type': type,
        'fuelType': fuelType,
        'tankCapacity': tankCapacity,
        'expectedFuelConsumption': expectedFuelConsumption,
        'currentOdometer': currentOdometer,
        'status': status.label,
        'assignedDriverId': assignedDriverId,
        'assignedDepartment': assignedDepartment,
        'insuranceExpiry': insuranceExpiry,
        'roadworthinessExpiry': roadworthinessExpiry,
        'gpsTrackerId': gpsTrackerId,
        'trackerStatus': trackerStatus.label,
        'lastGpsLocation': lastGpsLocation.toJson(),
        'lastGpsUpdateTime': lastGpsUpdateTime,
        'monthlyFuelLimit': monthlyFuelLimit,
        'currentMonthFuelUsed': currentMonthFuelUsed,
      };
}
