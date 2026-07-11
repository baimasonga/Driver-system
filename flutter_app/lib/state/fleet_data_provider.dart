import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_data.dart' as seed;
import '../models/models.dart';

/// Central app state: owns every collection, persists to device storage,
/// and implements the accountability / anti-fraud business rules that used
/// to live inside the React components (trip sign-out/in, fuel variance
/// detection, maintenance workflow, exceptions, audit trail).
class FleetDataProvider extends ChangeNotifier {
  final Random _rng = Random();

  List<Vehicle> vehicles = [];
  List<Driver> drivers = [];
  List<Trip> trips = [];
  List<FuelRequest> fuelRequests = [];
  List<MaintenanceRequest> maintenanceRequests = [];
  List<ExceptionRecord> exceptions = [];
  List<Incident> incidents = [];
  List<AuditLog> auditLogs = [];
  List<PolicyRule> policyRules = [];
  List<SparePart> spareParts = [];
  List<Tyre> tyres = [];
  List<Inspection> inspections = [];

  bool isLoaded = false;

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final hasData = _prefs!.containsKey('fleet_vehicles');
    if (hasData) {
      vehicles = _readList('fleet_vehicles', Vehicle.fromJson);
      drivers = _readList('fleet_drivers', Driver.fromJson);
      trips = _readList('fleet_trips', Trip.fromJson);
      fuelRequests = _readList('fleet_fuel_requests', FuelRequest.fromJson);
      maintenanceRequests = _readList('fleet_maintenance_requests', MaintenanceRequest.fromJson);
      exceptions = _readList('fleet_exceptions', ExceptionRecord.fromJson);
      incidents = _readList('fleet_incidents', Incident.fromJson);
      auditLogs = _readList('fleet_audit_logs', AuditLog.fromJson);
      policyRules = _readList('fleet_policy_rules', PolicyRule.fromJson);
      spareParts = _readList('fleet_spare_parts', SparePart.fromJson);
      tyres = _readList('fleet_tyres', Tyre.fromJson);
      inspections = _readList('fleet_inspections', Inspection.fromJson);
    } else {
      resetToDefault(persist: false);
    }
    isLoaded = true;
    notifyListeners();
  }

  List<T> _readList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs?.getString(key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _write(String key, List<dynamic> list) async {
    await _prefs?.setString(key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  void resetToDefault({bool persist = true}) {
    vehicles = List.of(seed.defaultVehicles);
    drivers = List.of(seed.defaultDrivers);
    trips = List.of(seed.defaultTrips);
    fuelRequests = List.of(seed.defaultFuelRequests);
    maintenanceRequests = List.of(seed.defaultMaintenanceRequests);
    exceptions = List.of(seed.defaultExceptions);
    incidents = List.of(seed.defaultIncidents);
    auditLogs = List.of(seed.defaultAuditLogs);
    policyRules = List.of(seed.defaultPolicyRules);
    spareParts = List.of(seed.defaultSpareParts);
    tyres = List.of(seed.defaultTyres);
    inspections = List.of(seed.defaultInspections);
    if (persist) _persistAll();
    notifyListeners();
  }

  void _persistAll() {
    _write('fleet_vehicles', vehicles);
    _write('fleet_drivers', drivers);
    _write('fleet_trips', trips);
    _write('fleet_fuel_requests', fuelRequests);
    _write('fleet_maintenance_requests', maintenanceRequests);
    _write('fleet_exceptions', exceptions);
    _write('fleet_incidents', incidents);
    _write('fleet_audit_logs', auditLogs);
    _write('fleet_policy_rules', policyRules);
    _write('fleet_spare_parts', spareParts);
    _write('fleet_tyres', tyres);
    _write('fleet_inspections', inspections);
  }

  String _genId(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}${_rng.nextInt(999)}';

  // ---------------------------------------------------------------------
  // Lookups
  // ---------------------------------------------------------------------

  Vehicle? vehicleById(String id) => vehicles.where((v) => v.id == id).firstOrNull;
  Driver? driverById(String id) => drivers.where((d) => d.id == id).firstOrNull;
  Vehicle? vehicleForDriver(String driverId) => vehicles.where((v) => v.assignedDriverId == driverId).firstOrNull;

  Trip? activeTripForDriver(String driverId) =>
      trips.where((t) => t.driverId == driverId && t.status == TripStatus.active).firstOrNull;
  Trip? pendingTripForDriver(String driverId) =>
      trips.where((t) => t.driverId == driverId && t.status == TripStatus.approved).firstOrNull;

  // ---------------------------------------------------------------------
  // Audit / Blackbox trail
  // ---------------------------------------------------------------------

  void addAuditLog({required String userId, required String userRole, required String action, required String entityType, required String entityId, required String details}) {
    auditLogs = [
      AuditLog(
        id: _genId('log'),
        timestamp: DateTime.now().toIso8601String(),
        userId: userId,
        userRole: userRole,
        action: action,
        entityType: entityType,
        entityId: entityId,
        details: details,
      ),
      ...auditLogs,
    ];
    _write('fleet_audit_logs', auditLogs);
    notifyListeners();
  }

  void _raiseException({
    required String type,
    required ExceptionSeverity severity,
    required String title,
    required String description,
    required String vehicleId,
    String? driverId,
  }) {
    final id = _genId('exc');
    exceptions = [
      ExceptionRecord(
        id: id,
        type: type,
        severity: severity,
        title: title,
        description: description,
        vehicleId: vehicleId,
        driverId: driverId,
        timestamp: DateTime.now().toIso8601String(),
        status: 'Open',
      ),
      ...exceptions,
    ];
    _write('fleet_exceptions', exceptions);
    addAuditLog(
      userId: 'System (Fraud Detection)',
      userRole: 'Security Core',
      action: 'ALERT DETECTED',
      entityType: 'Exception',
      entityId: id,
      details: title,
    );
  }

  void resolveException(String id, {required String resolvedBy, required String resolutionNotes}) {
    exceptions = exceptions
        .map((e) => e.id == id ? e.copyWith(status: 'Resolved', resolutionNotes: resolutionNotes, resolvedBy: resolvedBy) : e)
        .toList();
    _write('fleet_exceptions', exceptions);
    addAuditLog(
      userId: resolvedBy,
      userRole: 'Fleet Manager',
      action: 'Sealed Exception File',
      entityType: 'Exception',
      entityId: id,
      details: resolutionNotes,
    );
    notifyListeners();
  }

  void setExceptionStatus(String id, String status) {
    exceptions = exceptions.map((e) => e.id == id ? e.copyWith(status: status) : e).toList();
    _write('fleet_exceptions', exceptions);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Trip lifecycle: Request -> Approve -> Sign-Out (Gate) -> Active ->
  // Sign-In (Gate) -> Completed / Flagged
  // ---------------------------------------------------------------------

  Trip requestTrip({
    required String vehicleId,
    required String driverId,
    required String department,
    required List<String> passengers,
    String? cargoNotes,
    required String purpose,
    required String pickupPoint,
    required String destination,
  }) {
    final trip = Trip(
      id: _genId('t'),
      tripRequestNumber: 'TRIP-${DateTime.now().year}-${(trips.length + 1000)}',
      vehicleId: vehicleId,
      driverId: driverId,
      department: department,
      passengers: passengers,
      cargoNotes: cargoNotes,
      purpose: purpose,
      pickupPoint: pickupPoint,
      destination: destination,
      status: TripStatus.requested,
      requestedAt: DateTime.now().toIso8601String(),
    );
    trips = [trip, ...trips];
    _write('fleet_trips', trips);
    final driver = driverById(driverId);
    addAuditLog(
      userId: driver?.name ?? driverId,
      userRole: 'Driver',
      action: 'Requested Trip',
      entityType: 'Trip',
      entityId: trip.id,
      details: 'Requested trip to $destination for "$purpose".',
    );
    notifyListeners();
    return trip;
  }

  void approveTrip(String tripId, {required String approver}) {
    trips = trips
        .map((t) => t.id == tripId
            ? t.copyWith(status: TripStatus.approved, approvedAt: DateTime.now().toIso8601String())
            : t)
        .toList();
    _write('fleet_trips', trips);
    addAuditLog(
      userId: approver,
      userRole: 'Fleet Manager',
      action: 'Approved Trip',
      entityType: 'Trip',
      entityId: tripId,
      details: 'Trip request approved for dispatch.',
    );
    notifyListeners();
  }

  void signOutTrip(String tripId, {required double odometer, required double fuelLevel, required String officerName}) {
    final trip = trips.firstWhereOrNull((t) => t.id == tripId);
    if (trip == null) return;
    // Simulate the tamper-proof GPS tracker's expected route distance for
    // this trip so the sign-in fraud check has an independent reference
    // point to compare the driver-reported odometer delta against.
    final simulatedGpsDistanceKm = (8 + _rng.nextInt(55)).toDouble();
    trips = trips
        .map((t) => t.id == tripId
            ? t.copyWith(
                status: TripStatus.active,
                startedAt: DateTime.now().toIso8601String(),
                signOutOdometer: odometer,
                signOutFuelLevel: fuelLevel,
                signOutOfficerName: officerName,
                signOutTime: DateTime.now().toIso8601String(),
                gpsDistanceKm: simulatedGpsDistanceKm,
              )
            : t)
        .toList();
    _write('fleet_trips', trips);
    vehicles = vehicles.map((v) => v.id == trip.vehicleId ? v.copyWith(status: VehicleStatus.active) : v).toList();
    _write('fleet_vehicles', vehicles);
    addAuditLog(
      userId: officerName,
      userRole: 'Gate Officer',
      action: 'Gate Sign-Out',
      entityType: 'Trip',
      entityId: tripId,
      details: 'Vehicle dispatched at odometer $odometer km, fuel level $fuelLevel%.',
    );
    notifyListeners();
  }

  /// Ends a trip and runs the odometer-vs-GPS fraud check.
  /// [gpsDistanceKm] simulates the tamper-proof tracker reading; if omitted
  /// the trip's existing value (or the reported distance) is used.
  void signInTrip(
    String tripId, {
    required double odometer,
    required double fuelLevel,
    required String officerName,
    double? gpsDistanceKm,
  }) {
    final trip = trips.firstWhereOrNull((t) => t.id == tripId);
    if (trip == null) return;
    final driver = driverById(trip.driverId);
    final startOdo = trip.signOutOdometer ?? odometer;
    final reportedDist = odometer - startOdo;
    final gpsDist = gpsDistanceKm ?? trip.gpsDistanceKm ?? reportedDist;

    final fraudDetected = gpsDist > 0 && reportedDist > gpsDist * 1.4;
    final newStatus = fraudDetected ? TripStatus.flagged : TripStatus.completed;

    trips = trips
        .map((t) => t.id == tripId
            ? t.copyWith(
                status: newStatus,
                endedAt: DateTime.now().toIso8601String(),
                signInOdometer: odometer,
                signInFuelLevel: fuelLevel,
                signInOfficerName: officerName,
                signInTime: DateTime.now().toIso8601String(),
                gpsDistanceKm: gpsDist,
                routeDeviationFlagged: fraudDetected,
              )
            : t)
        .toList();
    _write('fleet_trips', trips);

    vehicles = vehicles
        .map((v) => v.id == trip.vehicleId ? v.copyWith(currentOdometer: odometer, status: VehicleStatus.parked) : v)
        .toList();
    _write('fleet_vehicles', vehicles);

    addAuditLog(
      userId: officerName,
      userRole: 'Gate Officer',
      action: 'Gate Sign-In',
      entityType: 'Trip',
      entityId: tripId,
      details: 'Vehicle returned at odometer $odometer km (+${reportedDist.toStringAsFixed(1)} km), fuel level $fuelLevel%.',
    );

    if (fraudDetected) {
      _raiseException(
        type: 'Trip',
        severity: ExceptionSeverity.high,
        title: 'Odometer Inflation / Route Falsification',
        description:
            'Driver ${driver?.name ?? trip.driverId} completed trip ${trip.tripRequestNumber} with final odometer $odometer '
            '(+${reportedDist.toStringAsFixed(1)}km), but GPS tracking recorded only ${gpsDist.toStringAsFixed(1)}km travelled. '
            'Discrepancy of ${(reportedDist - gpsDist).toStringAsFixed(1)}km suggests manual odometer tampering or unauthorized sideline trips.',
        vehicleId: trip.vehicleId,
        driverId: trip.driverId,
      );
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Fuel: driver submits -> manager approves/rejects -> variance detection
  // ---------------------------------------------------------------------

  FuelRequest submitFuelRequest({
    required String vehicleId,
    required String driverId,
    required double odometer,
    required double requestedLiters,
    required double estimatedCost,
    required String stationName,
    String? receiptPhotoUrl,
    String? pumpPhotoUrl,
  }) {
    final req = FuelRequest(
      id: _genId('f'),
      vehicleId: vehicleId,
      driverId: driverId,
      odometer: odometer,
      requestedLiters: requestedLiters,
      estimatedCost: estimatedCost,
      stationName: stationName,
      timestamp: DateTime.now().toIso8601String(),
      status: 'Pending',
      voucherCode: 'F-VOUCH-${1000 + _rng.nextInt(89999)}',
      receiptPhotoUrl: receiptPhotoUrl,
      pumpPhotoUrl: pumpPhotoUrl,
    );
    fuelRequests = [req, ...fuelRequests];
    _write('fleet_fuel_requests', fuelRequests);
    final driver = driverById(driverId);
    addAuditLog(
      userId: driver?.name ?? driverId,
      userRole: 'Driver',
      action: 'Requested Fuel',
      entityType: 'FuelRequest',
      entityId: req.id,
      details: 'Requested $requestedLiters L at $stationName.',
    );
    notifyListeners();
    return req;
  }

  /// Distance travelled since the last completed/flagged trip for this
  /// vehicle, used as the denominator for the km/L consumption check.
  double _distanceSinceLastTrip(String vehicleId) {
    final relevant = trips.where((t) =>
        t.vehicleId == vehicleId &&
        (t.status == TripStatus.completed || t.status == TripStatus.flagged) &&
        t.gpsDistanceKm != null);
    if (relevant.isEmpty) return 60; // reasonable default so div-by-zero can't happen
    final latest = relevant.reduce((a, b) => (a.endedAt ?? '').compareTo(b.endedAt ?? '') > 0 ? a : b);
    return latest.gpsDistanceKm ?? 60;
  }

  void approveFuelRequest(String id, {required String approver}) {
    final req = fuelRequests.firstWhereOrNull((f) => f.id == id);
    final vehicle = req == null ? null : vehicleById(req.vehicleId);
    if (req == null || vehicle == null) return;

    final distance = _distanceSinceLastTrip(vehicle.id);
    final calculatedConsumption = req.requestedLiters > 0 ? distance / req.requestedLiters : 0;
    final expected = vehicle.expectedFuelConsumption;
    final flagged = expected > 0 && calculatedConsumption < expected * 0.4;

    fuelRequests = fuelRequests
        .map((f) => f.id == id
            ? f.copyWith(
                status: 'Completed',
                approvedLiters: req.requestedLiters,
                actualLiters: req.requestedLiters,
                actualCost: req.estimatedCost,
                varianceFlagged: flagged,
                varianceReason: flagged
                    ? 'Calculated consumption is ${calculatedConsumption.toStringAsFixed(1)} km/L, which is far below the '
                        'expected ${expected.toStringAsFixed(1)} km/L for this vehicle. Highly indicative of fuel siphoning '
                        'or receipt inflation.'
                    : null,
              )
            : f)
        .toList();
    _write('fleet_fuel_requests', fuelRequests);

    vehicles = vehicles
        .map((v) => v.id == vehicle.id ? v.copyWith(currentMonthFuelUsed: v.currentMonthFuelUsed + req.requestedLiters) : v)
        .toList();
    _write('fleet_vehicles', vehicles);

    addAuditLog(
      userId: approver,
      userRole: 'Fleet Manager',
      action: 'Approved Fuel Request',
      entityType: 'FuelRequest',
      entityId: id,
      details: 'Approved ${req.requestedLiters} L voucher ${req.voucherCode} for ${vehicle.registrationNumber}.',
    );

    if (flagged) {
      _raiseException(
        type: 'Fuel',
        severity: ExceptionSeverity.critical,
        title: 'Extreme Fuel Consumption Variance',
        description:
            'Refuel transaction for vehicle ${vehicle.registrationNumber} recorded ${req.requestedLiters} L filled at '
            '${req.stationName}. Calculated mileage consumption is ${calculatedConsumption.toStringAsFixed(1)} km/L, deviating '
            'drastically from the expected ${expected.toStringAsFixed(1)} km/L.',
        vehicleId: vehicle.id,
        driverId: req.driverId,
      );
    }
    notifyListeners();
  }

  void rejectFuelRequest(String id, {required String approver, required String reason}) {
    fuelRequests = fuelRequests.map((f) => f.id == id ? f.copyWith(status: 'Rejected') : f).toList();
    _write('fleet_fuel_requests', fuelRequests);
    addAuditLog(
      userId: approver,
      userRole: 'Fleet Manager',
      action: 'Rejected Fuel Request',
      entityType: 'FuelRequest',
      entityId: id,
      details: reason,
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Maintenance: Pending -> Approved -> In Garage -> Completed -> Verified
  // ---------------------------------------------------------------------

  MaintenanceRequest submitMaintenanceRequest({
    required String vehicleId,
    required String driverId,
    required String category,
    required String description,
    required String severity,
    required double odometer,
    String? beforePhotoUrl,
  }) {
    final req = MaintenanceRequest(
      id: _genId('m'),
      vehicleId: vehicleId,
      driverId: driverId,
      category: category,
      description: description,
      severity: severity,
      odometer: odometer,
      timestamp: DateTime.now().toIso8601String(),
      status: MaintenanceStatus.pending,
      beforePhotoUrl: beforePhotoUrl,
    );
    maintenanceRequests = [req, ...maintenanceRequests];
    _write('fleet_maintenance_requests', maintenanceRequests);
    final driver = driverById(driverId);
    addAuditLog(
      userId: driver?.name ?? driverId,
      userRole: 'Driver',
      action: 'Requested Maintenance',
      entityType: 'MaintenanceRequest',
      entityId: req.id,
      details: description,
    );
    notifyListeners();
    return req;
  }

  void approveMaintenanceRequest(String id, {required String approver, required double approvedAmount}) {
    maintenanceRequests = maintenanceRequests
        .map((m) => m.id == id ? m.copyWith(status: MaintenanceStatus.approved, approvedAmount: approvedAmount) : m)
        .toList();
    _write('fleet_maintenance_requests', maintenanceRequests);
    addAuditLog(
      userId: approver,
      userRole: 'Fleet Manager',
      action: 'Approved Maintenance Request',
      entityType: 'MaintenanceRequest',
      entityId: id,
      details: 'Approved budget of \$${approvedAmount.toStringAsFixed(2)}.',
    );
    notifyListeners();
  }

  void dispatchToGarage(String id, {required String dispatcher, required String garageName}) {
    maintenanceRequests =
        maintenanceRequests.map((m) => m.id == id ? m.copyWith(status: MaintenanceStatus.inGarage, garageName: garageName) : m).toList();
    _write('fleet_maintenance_requests', maintenanceRequests);
    addAuditLog(
      userId: dispatcher,
      userRole: 'Fleet Manager',
      action: 'Dispatched Work Order',
      entityType: 'MaintenanceRequest',
      entityId: id,
      details: 'Dispatched to $garageName.',
    );
    notifyListeners();
  }

  void completeMaintenanceRequest(
    String id, {
    required String completedBy,
    required double invoiceAmount,
    String? invoicePhotoUrl,
    String? afterPhotoUrl,
    String? completionNotes,
    bool testDrivePassed = true,
  }) {
    maintenanceRequests = maintenanceRequests
        .map((m) => m.id == id
            ? m.copyWith(
                status: MaintenanceStatus.completed,
                invoiceAmount: invoiceAmount,
                invoicePhotoUrl: invoicePhotoUrl,
                afterPhotoUrl: afterPhotoUrl,
                completionNotes: completionNotes,
                testDrivePassed: testDrivePassed,
              )
            : m)
        .toList();
    _write('fleet_maintenance_requests', maintenanceRequests);

    final req = maintenanceRequests.firstWhereOrNull((m) => m.id == id);
    if (req != null && req.approvedAmount != null && (invoiceAmount - req.approvedAmount!).abs() > req.approvedAmount! * 0.15) {
      _raiseException(
        type: 'Maintenance',
        severity: ExceptionSeverity.medium,
        title: 'Invoice Exceeds Approved Quotation',
        description:
            'Invoice of \$${invoiceAmount.toStringAsFixed(2)} deviates by more than 15% from the approved amount of '
            '\$${req.approvedAmount!.toStringAsFixed(2)} for maintenance request $id.',
        vehicleId: req.vehicleId,
        driverId: req.driverId,
      );
    }

    addAuditLog(
      userId: completedBy,
      userRole: 'Garage',
      action: 'Completed Maintenance',
      entityType: 'MaintenanceRequest',
      entityId: id,
      details: completionNotes ?? 'Repair marked complete, invoice \$${invoiceAmount.toStringAsFixed(2)}.',
    );
    notifyListeners();
  }

  void verifyMaintenanceRequest(String id, {required String verifier}) {
    maintenanceRequests = maintenanceRequests.map((m) => m.id == id ? m.copyWith(status: MaintenanceStatus.verified) : m).toList();
    _write('fleet_maintenance_requests', maintenanceRequests);
    addAuditLog(
      userId: verifier,
      userRole: 'Fleet Manager',
      action: 'Verified Repair',
      entityType: 'MaintenanceRequest',
      entityId: id,
      details: 'Odometer and parts serials verified against invoice.',
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Inspections (pre/post trip checklist)
  // ---------------------------------------------------------------------

  Inspection submitInspection({
    String? tripId,
    required String vehicleId,
    required String driverId,
    required String type,
    required bool fuelLevelOk,
    required bool oilLevelOk,
    required bool coolantOk,
    required bool tyresOk,
    required bool brakesOk,
    required bool lightsOk,
    required bool bodyConditionOk,
    required bool spareTyreToolsOk,
    String? notes,
  }) {
    final insp = Inspection(
      id: _genId('insp'),
      tripId: tripId,
      vehicleId: vehicleId,
      driverId: driverId,
      timestamp: DateTime.now().toIso8601String(),
      type: type,
      fuelLevelOk: fuelLevelOk,
      oilLevelOk: oilLevelOk,
      coolantOk: coolantOk,
      tyresOk: tyresOk,
      brakesOk: brakesOk,
      lightsOk: lightsOk,
      bodyConditionOk: bodyConditionOk,
      spareTyreToolsOk: spareTyreToolsOk,
      notes: notes,
    );
    inspections = [insp, ...inspections];
    _write('fleet_inspections', inspections);
    final driver = driverById(driverId);
    addAuditLog(
      userId: driver?.name ?? driverId,
      userRole: 'Driver',
      action: '$type Inspection Submitted',
      entityType: 'Inspection',
      entityId: insp.id,
      details: insp.allPassed ? 'All checklist items passed.' : 'One or more checklist items failed: ${notes ?? ''}',
    );
    if (!insp.allPassed) {
      _raiseException(
        type: 'Trip',
        severity: ExceptionSeverity.medium,
        title: '$type Inspection Failed Checklist Item(s)',
        description: 'Driver ${driver?.name ?? driverId} reported a failed vehicle condition item during $type inspection. '
            '${notes != null && notes.isNotEmpty ? "Notes: $notes" : ""}',
        vehicleId: vehicleId,
        driverId: driverId,
      );
    }
    notifyListeners();
    return insp;
  }

  // ---------------------------------------------------------------------
  // Incidents
  // ---------------------------------------------------------------------

  Incident reportIncident({
    required String category,
    required String vehicleId,
    required String driverId,
    required String description,
    required String location,
    String? photoUrl,
  }) {
    final incident = Incident(
      id: _genId('in'),
      category: category,
      timestamp: DateTime.now().toIso8601String(),
      vehicleId: vehicleId,
      driverId: driverId,
      description: description,
      location: location,
      photoUrl: photoUrl,
      status: 'Pending',
    );
    incidents = [incident, ...incidents];
    _write('fleet_incidents', incidents);
    final driver = driverById(driverId);
    addAuditLog(
      userId: driver?.name ?? driverId,
      userRole: 'Driver',
      action: 'Reported Incident',
      entityType: 'Incident',
      entityId: incident.id,
      details: '$category: $description',
    );
    notifyListeners();
    return incident;
  }

  void updateIncidentStatus(String id, String status, {required String updatedBy}) {
    incidents = incidents.map((i) => i.id == id ? i.copyWith(status: status) : i).toList();
    _write('fleet_incidents', incidents);
    addAuditLog(
      userId: updatedBy,
      userRole: 'Fleet Manager',
      action: 'Updated Incident Status',
      entityType: 'Incident',
      entityId: id,
      details: 'Status set to $status.',
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Policies & spare parts
  // ---------------------------------------------------------------------

  void updatePolicyRuleValue(String id, String newValue, {required String updatedBy}) {
    final old = policyRules.firstWhereOrNull((p) => p.id == id);
    policyRules = policyRules.map((p) => p.id == id ? p.copyWith(value: newValue) : p).toList();
    _write('fleet_policy_rules', policyRules);
    addAuditLog(
      userId: updatedBy,
      userRole: 'System Admin',
      action: 'Rule Change',
      entityType: 'PolicyRule',
      entityId: id,
      details: 'Updated ${old?.name ?? id} value from "${old?.value}" to "$newValue".',
    );
    notifyListeners();
  }

  void adjustSparePartStock(String id, int delta, {required String updatedBy}) {
    spareParts = spareParts.map((s) => s.id == id ? s.copyWith(stockQty: (s.stockQty + delta).clamp(0, 1 << 30).toInt()) : s).toList();
    _write('fleet_spare_parts', spareParts);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Vehicle status / tracker
  // ---------------------------------------------------------------------

  void setVehicleStatus(String id, VehicleStatus status) {
    vehicles = vehicles.map((v) => v.id == id ? v.copyWith(status: status) : v).toList();
    _write('fleet_vehicles', vehicles);
    notifyListeners();
  }
}

extension FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
