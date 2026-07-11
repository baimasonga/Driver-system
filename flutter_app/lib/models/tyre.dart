class Tyre {
  final String id;
  final String vehicleId;
  final String brand;
  final String size;
  final String serialNumber;
  final String position; // Front-Left | Front-Right | Rear-Left | Rear-Right | Spare
  final double installedAtOdometer;
  final double? removedAtOdometer;
  final String installationDate;
  final String condition; // New | Good | Worn | Replaced

  const Tyre({
    required this.id,
    required this.vehicleId,
    required this.brand,
    required this.size,
    required this.serialNumber,
    required this.position,
    required this.installedAtOdometer,
    this.removedAtOdometer,
    required this.installationDate,
    required this.condition,
  });

  factory Tyre.fromJson(Map<String, dynamic> json) => Tyre(
        id: json['id'],
        vehicleId: json['vehicleId'],
        brand: json['brand'],
        size: json['size'],
        serialNumber: json['serialNumber'],
        position: json['position'],
        installedAtOdometer: (json['installedAtOdometer'] as num).toDouble(),
        removedAtOdometer: (json['removedAtOdometer'] as num?)?.toDouble(),
        installationDate: json['installationDate'],
        condition: json['condition'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'brand': brand,
        'size': size,
        'serialNumber': serialNumber,
        'position': position,
        'installedAtOdometer': installedAtOdometer,
        'removedAtOdometer': removedAtOdometer,
        'installationDate': installationDate,
        'condition': condition,
      };
}
