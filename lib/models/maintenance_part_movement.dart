class MaintenancePartMovement {
  final String id;
  final String maintenanceRequestId;
  final String? sparePartId;
  final String vehicleId;
  final String partName;
  final String? partNumber;
  final String removedSerialNumber;
  final String installedSerialNumber;
  final String removedCondition;
  final int quantity;
  final double unitCost;
  final String capturedBy;
  final String capturedAt;

  const MaintenancePartMovement({required this.id, required this.maintenanceRequestId,
    this.sparePartId, required this.vehicleId, required this.partName, this.partNumber,
    required this.removedSerialNumber, required this.installedSerialNumber,
    required this.removedCondition, required this.quantity, required this.unitCost,
    required this.capturedBy, required this.capturedAt});

  factory MaintenancePartMovement.fromJson(Map<String, dynamic> j) => MaintenancePartMovement(
    id: j['id'], maintenanceRequestId: j['maintenanceRequestId'], sparePartId: j['sparePartId'],
    vehicleId: j['vehicleId'], partName: j['partName'], partNumber: j['partNumber'],
    removedSerialNumber: j['removedSerialNumber'], installedSerialNumber: j['installedSerialNumber'],
    removedCondition: j['removedCondition'], quantity: j['quantity'],
    unitCost: (j['unitCost'] as num).toDouble(), capturedBy: j['capturedBy'], capturedAt: j['capturedAt']);
}
