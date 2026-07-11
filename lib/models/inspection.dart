class Inspection {
  final String id;
  final String? tripId;
  final String vehicleId;
  final String driverId;
  final String timestamp;
  final String type; // Pre-Trip | Post-Trip

  final bool fuelLevelOk;
  final bool oilLevelOk;
  final bool coolantOk;
  final bool tyresOk;
  final bool brakesOk;
  final bool lightsOk;
  final bool bodyConditionOk;
  final bool spareTyreToolsOk;

  final String? notes;
  final String? photoUrl;

  const Inspection({
    required this.id,
    this.tripId,
    required this.vehicleId,
    required this.driverId,
    required this.timestamp,
    required this.type,
    required this.fuelLevelOk,
    required this.oilLevelOk,
    required this.coolantOk,
    required this.tyresOk,
    required this.brakesOk,
    required this.lightsOk,
    required this.bodyConditionOk,
    required this.spareTyreToolsOk,
    this.notes,
    this.photoUrl,
  });

  bool get allPassed =>
      fuelLevelOk && oilLevelOk && coolantOk && tyresOk && brakesOk && lightsOk && bodyConditionOk && spareTyreToolsOk;

  factory Inspection.fromJson(Map<String, dynamic> json) => Inspection(
        id: json['id'],
        tripId: json['tripId'],
        vehicleId: json['vehicleId'],
        driverId: json['driverId'],
        timestamp: json['timestamp'],
        type: json['type'],
        fuelLevelOk: json['fuelLevelOk'],
        oilLevelOk: json['oilLevelOk'],
        coolantOk: json['coolantOk'],
        tyresOk: json['tyresOk'],
        brakesOk: json['brakesOk'],
        lightsOk: json['lightsOk'],
        bodyConditionOk: json['bodyConditionOk'],
        spareTyreToolsOk: json['spareTyreToolsOk'],
        notes: json['notes'],
        photoUrl: json['photoUrl'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'vehicleId': vehicleId,
        'driverId': driverId,
        'timestamp': timestamp,
        'type': type,
        'fuelLevelOk': fuelLevelOk,
        'oilLevelOk': oilLevelOk,
        'coolantOk': coolantOk,
        'tyresOk': tyresOk,
        'brakesOk': brakesOk,
        'lightsOk': lightsOk,
        'bodyConditionOk': bodyConditionOk,
        'spareTyreToolsOk': spareTyreToolsOk,
        'notes': notes,
        'photoUrl': photoUrl,
      };
}
