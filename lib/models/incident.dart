class Incident {
  final String id;
  final String category; // Accident | Breakdown | Violation | Theft | Passenger Complaint
  final String timestamp;
  final String vehicleId;
  final String driverId;
  final String description;
  final String location;
  final String? photoUrl;
  final String status; // Pending | Under Investigation | Resolved

  const Incident({
    required this.id,
    required this.category,
    required this.timestamp,
    required this.vehicleId,
    required this.driverId,
    required this.description,
    required this.location,
    this.photoUrl,
    required this.status,
  });

  Incident copyWith({String? status}) => Incident(
        id: id,
        category: category,
        timestamp: timestamp,
        vehicleId: vehicleId,
        driverId: driverId,
        description: description,
        location: location,
        photoUrl: photoUrl,
        status: status ?? this.status,
      );

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
        id: json['id'],
        category: json['category'],
        timestamp: json['timestamp'],
        vehicleId: json['vehicleId'],
        driverId: json['driverId'],
        description: json['description'],
        location: json['location'],
        photoUrl: json['photoUrl'],
        status: json['status'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'timestamp': timestamp,
        'vehicleId': vehicleId,
        'driverId': driverId,
        'description': description,
        'location': location,
        'photoUrl': photoUrl,
        'status': status,
      };
}
