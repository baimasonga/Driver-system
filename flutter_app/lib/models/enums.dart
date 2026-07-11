enum VehicleStatus {
  active("Active"),
  parked("Parked"),
  underMaintenance("Under Maintenance"),
  grounded("Grounded"),
  retired("Retired");

  final String label;
  const VehicleStatus(this.label);

  static VehicleStatus fromLabel(String label) =>
      VehicleStatus.values.firstWhere((e) => e.label == label, orElse: () => VehicleStatus.active);
}

enum TrackerStatus {
  active("Active"),
  offline("Offline"),
  tampered("Tampered"),
  removed("Removed");

  final String label;
  const TrackerStatus(this.label);

  static TrackerStatus fromLabel(String label) =>
      TrackerStatus.values.firstWhere((e) => e.label == label, orElse: () => TrackerStatus.active);
}

enum TripStatus {
  requested("Requested"),
  approved("Approved"),
  active("Active"),
  completed("Completed"),
  overdue("Overdue"),
  flagged("Flagged");

  final String label;
  const TripStatus(this.label);

  static TripStatus fromLabel(String label) =>
      TripStatus.values.firstWhere((e) => e.label == label, orElse: () => TripStatus.requested);
}

enum DriverStatus {
  active("Active"),
  suspended("Suspended"),
  onLeave("On Leave"),
  exited("Exited");

  final String label;
  const DriverStatus(this.label);

  static DriverStatus fromLabel(String label) =>
      DriverStatus.values.firstWhere((e) => e.label == label, orElse: () => DriverStatus.active);
}

enum MaintenanceStatus {
  pending("Pending Approval"),
  approved("Approved"),
  inGarage("In Garage"),
  completed("Completed"),
  verified("Verified");

  final String label;
  const MaintenanceStatus(this.label);

  static MaintenanceStatus fromLabel(String label) =>
      MaintenanceStatus.values.firstWhere((e) => e.label == label, orElse: () => MaintenanceStatus.pending);
}

enum ExceptionSeverity {
  low("Low"),
  medium("Medium"),
  high("High"),
  critical("Critical");

  final String label;
  const ExceptionSeverity(this.label);

  static ExceptionSeverity fromLabel(String label) =>
      ExceptionSeverity.values.firstWhere((e) => e.label == label, orElse: () => ExceptionSeverity.low);
}
