import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_mappers.dart';
import '../models/models.dart';

/// Central app state: owns every collection, syncs it with the Supabase
/// backend (so the web console and the driver app share one live source of
/// truth via Realtime), and implements the accountability / anti-fraud
/// business rules (trip sign-out/in, fuel variance detection, maintenance
/// workflow, exceptions, audit trail).
///
/// Writes are optimistic: the in-memory lists update immediately for a
/// snappy UI, then the change is pushed to Supabase in the background.
/// Realtime subscriptions reconcile state across every connected client
/// (e.g. a driver's phone raising an exception shows up on the manager's
/// web console without a refresh).
class FleetDataProvider extends ChangeNotifier {
  final Random _rng = Random();
  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _channel;

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
  bool isLoading = false;
  String? loadError;

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    try {
      await Future.wait([
        _reloadVehicles(),
        _reloadDrivers(),
        _reloadTrips(),
        _reloadFuelRequests(),
        _reloadMaintenanceRequests(),
        _reloadExceptions(),
        _reloadIncidents(),
        _reloadAuditLogs(),
        _reloadPolicyRules(),
        _reloadSpareParts(),
        _reloadTyres(),
        _reloadInspections(),
      ]);
      loadError = null;
      _subscribeRealtime();
    } catch (error) {
      // Surface the failure instead of leaving the app stuck on the loading
      // spinner -- screens can still render (with whatever partial data
      // came back) and the caller can offer a retry.
      debugPrint('FleetDataProvider.load failed: $error');
      loadError = error.toString();
    } finally {
      isLoading = false;
      isLoaded = true;
      notifyListeners();
    }
  }

  void _subscribeRealtime() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
    }
    _channel = _client.channel('public:fleet-sync')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'vehicles',
        callback: (_) => _reloadVehicles().then((_) => notifyListeners()),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'drivers',
        callback: (_) => _reloadDrivers().then((_) => notifyListeners()),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'trips',
        callback: (_) => _reloadTrips().then((_) => notifyListeners()),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'fuel_requests',
        callback: (_) => _reloadFuelRequests().then((_) => notifyListeners()),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'maintenance_requests',
        callback: (_) =>
            _reloadMaintenanceRequests().then((_) => notifyListeners()),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'exception_records',
        callback: (_) => _reloadExceptions().then((_) => notifyListeners()),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'incidents',
        callback: (_) => _reloadIncidents().then((_) => notifyListeners()),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'audit_logs',
        callback: (_) => _reloadAuditLogs().then((_) => notifyListeners()),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'policy_rules',
        callback: (_) => _reloadPolicyRules().then((_) => notifyListeners()),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'spare_parts',
        callback: (_) => _reloadSpareParts().then((_) => notifyListeners()),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'tyres',
        callback: (_) => _reloadTyres().then((_) => notifyListeners()),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'inspections',
        callback: (_) => _reloadInspections().then((_) => notifyListeners()),
      )
      ..subscribe();
  }

  @override
  void dispose() {
    if (_channel != null) _client.removeChannel(_channel!);
    super.dispose();
  }

  /// Drops the Realtime subscription and clears in-memory state on sign
  /// out, since RLS means a signed-out (or different) session can no
  /// longer see -- or shouldn't keep displaying -- this data.
  void reset() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
      _channel = null;
    }
    vehicles = [];
    drivers = [];
    trips = [];
    fuelRequests = [];
    maintenanceRequests = [];
    exceptions = [];
    incidents = [];
    auditLogs = [];
    policyRules = [];
    spareParts = [];
    tyres = [];
    inspections = [];
    isLoaded = false;
    isLoading = false;
    loadError = null;
    notifyListeners();
  }

  Future<void> _reloadVehicles() async {
    final rows = await _client.from('vehicles').select().order('created_at');
    vehicles = rows.map((r) => Vehicle.fromJson(vehicleRowToJson(r))).toList();
  }

  Future<void> _reloadDrivers() async {
    final rows = await _client.from('drivers').select().order('created_at');
    drivers = rows.map((r) => Driver.fromJson(driverRowToJson(r))).toList();
  }

  Future<void> _reloadTrips() async {
    final rows = await _client
        .from('trips')
        .select()
        .order('created_at', ascending: false);
    trips = rows.map((r) => Trip.fromJson(tripRowToJson(r))).toList();
  }

  Future<void> _reloadFuelRequests() async {
    final rows = await _client
        .from('fuel_requests')
        .select()
        .order('created_at', ascending: false);
    fuelRequests = rows
        .map((r) => FuelRequest.fromJson(fuelRequestRowToJson(r)))
        .toList();
  }

  Future<void> _reloadMaintenanceRequests() async {
    final rows = await _client
        .from('maintenance_requests')
        .select()
        .order('created_at', ascending: false);
    maintenanceRequests = rows
        .map((r) => MaintenanceRequest.fromJson(maintenanceRequestRowToJson(r)))
        .toList();
  }

  Future<void> _reloadExceptions() async {
    final rows = await _client
        .from('exception_records')
        .select()
        .order('created_at', ascending: false);
    exceptions = rows
        .map((r) => ExceptionRecord.fromJson(exceptionRowToJson(r)))
        .toList();
  }

  Future<void> _reloadIncidents() async {
    final rows = await _client
        .from('incidents')
        .select()
        .order('created_at', ascending: false);
    incidents = rows
        .map((r) => Incident.fromJson(incidentRowToJson(r)))
        .toList();
  }

  Future<void> _reloadAuditLogs() async {
    final rows = await _client
        .from('audit_logs')
        .select()
        .order('created_at', ascending: false);
    auditLogs = rows
        .map((r) => AuditLog.fromJson(auditLogRowToJson(r)))
        .toList();
  }

  Future<void> _reloadPolicyRules() async {
    final rows = await _client
        .from('policy_rules')
        .select()
        .order('created_at');
    policyRules = rows
        .map((r) => PolicyRule.fromJson(policyRuleRowToJson(r)))
        .toList();
  }

  Future<void> _reloadSpareParts() async {
    final rows = await _client.from('spare_parts').select().order('created_at');
    spareParts = rows
        .map((r) => SparePart.fromJson(sparePartRowToJson(r)))
        .toList();
  }

  Future<void> _reloadTyres() async {
    final rows = await _client.from('tyres').select().order('created_at');
    tyres = rows.map((r) => Tyre.fromJson(tyreRowToJson(r))).toList();
  }

  Future<void> _reloadInspections() async {
    final rows = await _client
        .from('inspections')
        .select()
        .order('created_at', ascending: false);
    inspections = rows
        .map((r) => Inspection.fromJson(inspectionRowToJson(r)))
        .toList();
  }

  // ---------------------------------------------------------------------
  // Optimistic write helpers: push one changed row to Supabase in the
  // background. Errors are logged, not thrown -- the Realtime subscription
  // above is the source of truth other clients reconcile against.
  // ---------------------------------------------------------------------

  // Best-effort background writes still used for secondary/derived state
  // (vehicle status changes, exception status toggles, spare-part stock,
  // audit lines) where a silent retry-on-next-reload is acceptable.
  void _pushVehicle(Vehicle v) => _upsert('vehicles', vehicleToRow(v));
  void _pushException(ExceptionRecord e) =>
      _upsert('exception_records', exceptionToRow(e));
  void _pushAuditLog(AuditLog l) => _upsert('audit_logs', auditLogToRow(l));
  void _pushSparePart(SparePart s) => _upsert('spare_parts', sparePartToRow(s));

  void _upsert(String table, Map<String, dynamic> row) {
    _client.from(table).upsert(row).catchError((Object error) {
      debugPrint('Supabase upsert into $table failed: $error');
      return <Map<String, dynamic>>[];
    });
  }

  /// Awaited write that throws on failure. Use this for records the user
  /// must know actually landed (a trip request, a fuel claim, a gate
  /// sign-in) so the caller can surface an error instead of the write
  /// silently vanishing on the next Realtime reload.
  Future<void> _persist(String table, Map<String, dynamic> row) =>
      _client.from(table).upsert(row);

  String _genId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}${_rng.nextInt(999)}';

  // ---------------------------------------------------------------------
  // Lookups
  // ---------------------------------------------------------------------

  Vehicle? vehicleById(String id) =>
      vehicles.where((v) => v.id == id).firstOrNull;
  Driver? driverById(String id) => drivers.where((d) => d.id == id).firstOrNull;
  Vehicle? vehicleForDriver(String driverId) =>
      vehicles.where((v) => v.assignedDriverId == driverId).firstOrNull;

  // ---------------------------------------------------------------------
  // Manager CRUD and fleet assignment rules
  // ---------------------------------------------------------------------

  Future<void> saveVehicle(Vehicle vehicle, {required String updatedBy}) async {
    final registration = vehicle.registrationNumber.trim().toUpperCase();
    final duplicateRegistration = vehicles.any(
      (v) =>
          v.id != vehicle.id &&
          v.registrationNumber.toUpperCase() == registration,
    );
    if (duplicateRegistration)
      throw StateError(
        'A vehicle with registration $registration already exists.',
      );
    final duplicateTracker =
        vehicle.gpsTrackerId.trim().isNotEmpty &&
        vehicles.any(
          (v) =>
              v.id != vehicle.id &&
              v.gpsTrackerId.toUpperCase() ==
                  vehicle.gpsTrackerId.trim().toUpperCase(),
        );
    if (duplicateTracker)
      throw StateError(
        'That GPS tracker is already assigned to another vehicle.',
      );
    if (vehicle.assignedDriverId.isNotEmpty) {
      final driver = driverById(vehicle.assignedDriverId);
      if (driver == null)
        throw StateError('The selected driver no longer exists.');
      if (driver.status != DriverStatus.active)
        throw StateError('Only active drivers can be assigned to vehicles.');
      if (DateTime.tryParse(driver.licenseExpiry)?.isBefore(DateTime.now()) ??
          true) {
        throw StateError(
          'The selected driver has an expired or invalid licence.',
        );
      }
    }

    final normalized = Vehicle(
      id: vehicle.id,
      registrationNumber: registration,
      make: vehicle.make.trim(),
      model: vehicle.model.trim(),
      year: vehicle.year,
      type: vehicle.type.trim(),
      fuelType: vehicle.fuelType,
      tankCapacity: vehicle.tankCapacity,
      expectedFuelConsumption: vehicle.expectedFuelConsumption,
      currentOdometer: vehicle.currentOdometer,
      status: vehicle.status,
      assignedDriverId: vehicle.assignedDriverId,
      assignedDepartment: vehicle.assignedDepartment.trim(),
      insuranceExpiry: vehicle.insuranceExpiry,
      roadworthinessExpiry: vehicle.roadworthinessExpiry,
      gpsTrackerId: vehicle.gpsTrackerId.trim(),
      trackerStatus: vehicle.trackerStatus,
      lastGpsLocation: vehicle.lastGpsLocation,
      lastGpsUpdateTime: vehicle.lastGpsUpdateTime,
      monthlyFuelLimit: vehicle.monthlyFuelLimit,
      currentMonthFuelUsed: vehicle.currentMonthFuelUsed,
    );
    await _client.from('vehicles').upsert(vehicleToRow(normalized));
    vehicles = [normalized, ...vehicles.where((v) => v.id != normalized.id)];
    // Enforce one active vehicle assignment per driver.
    if (normalized.assignedDriverId.isNotEmpty) {
      final previouslyAssigned = vehicles
          .where(
            (v) =>
                v.id != normalized.id &&
                v.assignedDriverId == normalized.assignedDriverId,
          )
          .toList();
      for (final other in previouslyAssigned) {
        final unassigned = Vehicle(
          id: other.id,
          registrationNumber: other.registrationNumber,
          make: other.make,
          model: other.model,
          year: other.year,
          type: other.type,
          fuelType: other.fuelType,
          tankCapacity: other.tankCapacity,
          expectedFuelConsumption: other.expectedFuelConsumption,
          currentOdometer: other.currentOdometer,
          status: other.status,
          assignedDriverId: '',
          assignedDepartment: other.assignedDepartment,
          insuranceExpiry: other.insuranceExpiry,
          roadworthinessExpiry: other.roadworthinessExpiry,
          gpsTrackerId: other.gpsTrackerId,
          trackerStatus: other.trackerStatus,
          lastGpsLocation: other.lastGpsLocation,
          lastGpsUpdateTime: other.lastGpsUpdateTime,
          monthlyFuelLimit: other.monthlyFuelLimit,
          currentMonthFuelUsed: other.currentMonthFuelUsed,
        );
        await _client.from('vehicles').upsert(vehicleToRow(unassigned));
        vehicles = vehicles
            .map((v) => v.id == unassigned.id ? unassigned : v)
            .toList();
      }
    }
    addAuditLog(
      userId: updatedBy,
      userRole: 'Fleet Manager',
      action: 'Saved Vehicle',
      entityType: 'Vehicle',
      entityId: normalized.id,
      details: '$registration fleet record saved.',
    );
    notifyListeners();
  }

  Future<void> deleteVehicle(String id, {required String deletedBy}) async {
    final hasHistory =
        trips.any((x) => x.vehicleId == id) ||
        fuelRequests.any((x) => x.vehicleId == id) ||
        maintenanceRequests.any((x) => x.vehicleId == id) ||
        incidents.any((x) => x.vehicleId == id);
    if (hasHistory)
      throw StateError(
        'This vehicle has operational history and cannot be deleted. Retire it instead.',
      );
    await _client.from('vehicles').delete().eq('id', id);
    vehicles.removeWhere((v) => v.id == id);
    addAuditLog(
      userId: deletedBy,
      userRole: 'Fleet Manager',
      action: 'Deleted Vehicle',
      entityType: 'Vehicle',
      entityId: id,
      details: 'Unused vehicle record deleted.',
    );
    notifyListeners();
  }

  Future<void> saveDriver(Driver driver, {required String updatedBy}) async {
    if (drivers.any(
      (d) =>
          d.id != driver.id &&
          d.staffNumber.toUpperCase() ==
              driver.staffNumber.trim().toUpperCase(),
    )) {
      throw StateError('That staff number is already in use.');
    }
    if (drivers.any(
      (d) =>
          d.id != driver.id &&
          d.email.toLowerCase() == driver.email.trim().toLowerCase(),
    )) {
      throw StateError('That email address is already in use.');
    }
    await _client.from('drivers').upsert(driverToRow(driver));
    drivers = [driver, ...drivers.where((d) => d.id != driver.id)];
    addAuditLog(
      userId: updatedBy,
      userRole: 'Fleet Manager',
      action: 'Saved Driver',
      entityType: 'Driver',
      entityId: driver.id,
      details: '${driver.name} driver record saved.',
    );
    notifyListeners();
  }

  Future<void> deleteDriver(String id, {required String deletedBy}) async {
    if (vehicleForDriver(id) != null)
      throw StateError('Unassign this driver from their vehicle first.');
    final hasHistory =
        trips.any((x) => x.driverId == id) ||
        fuelRequests.any((x) => x.driverId == id) ||
        maintenanceRequests.any((x) => x.driverId == id) ||
        incidents.any((x) => x.driverId == id);
    if (hasHistory)
      throw StateError(
        'This driver has operational history and cannot be deleted. Set the status to Exited instead.',
      );
    await _client.from('drivers').delete().eq('id', id);
    drivers.removeWhere((d) => d.id == id);
    addAuditLog(
      userId: deletedBy,
      userRole: 'Fleet Manager',
      action: 'Deleted Driver',
      entityType: 'Driver',
      entityId: id,
      details: 'Unused driver record deleted.',
    );
    notifyListeners();
  }

  Trip? activeTripForDriver(String driverId) => trips
      .where((t) => t.driverId == driverId && t.status == TripStatus.active)
      .firstOrNull;
  Trip? pendingTripForDriver(String driverId) => trips
      .where((t) => t.driverId == driverId && t.status == TripStatus.approved)
      .firstOrNull;

  // ---------------------------------------------------------------------
  // Audit / Blackbox trail
  // ---------------------------------------------------------------------

  void addAuditLog({
    required String userId,
    required String userRole,
    required String action,
    required String entityType,
    required String entityId,
    required String details,
  }) {
    final newLog = AuditLog(
      id: _genId('log'),
      timestamp: DateTime.now().toIso8601String(),
      userId: userId,
      userRole: userRole,
      action: action,
      entityType: entityType,
      entityId: entityId,
      details: details,
    );
    auditLogs = [newLog, ...auditLogs];
    _pushAuditLog(newLog);
    notifyListeners();
  }

  /// Raises an auto-detected fraud/policy exception. Best-effort: it is a
  /// side effect of a primary action that has already persisted, so a
  /// failure here is logged rather than surfaced to the user.
  Future<void> _raiseException({
    required String type,
    required ExceptionSeverity severity,
    required String title,
    required String description,
    required String vehicleId,
    String? driverId,
  }) async {
    final newException = ExceptionRecord(
      id: _genId('exc'),
      type: type,
      severity: severity,
      title: title,
      description: description,
      vehicleId: vehicleId,
      driverId: driverId,
      timestamp: DateTime.now().toIso8601String(),
      status: 'Open',
    );
    try {
      await _persist('exception_records', exceptionToRow(newException));
    } catch (error) {
      debugPrint('Failed to persist exception: $error');
    }
    exceptions = [newException, ...exceptions];
    addAuditLog(
      userId: 'System (Fraud Detection)',
      userRole: 'Security Core',
      action: 'ALERT DETECTED',
      entityType: 'Exception',
      entityId: newException.id,
      details: title,
    );
  }

  void resolveException(
    String id, {
    required String resolvedBy,
    required String resolutionNotes,
  }) {
    ExceptionRecord? updated;
    exceptions = exceptions.map((e) {
      if (e.id != id) return e;
      updated = e.copyWith(
        status: 'Resolved',
        resolutionNotes: resolutionNotes,
        resolvedBy: resolvedBy,
      );
      return updated!;
    }).toList();
    if (updated != null) _pushException(updated!);
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
    ExceptionRecord? updated;
    exceptions = exceptions.map((e) {
      if (e.id != id) return e;
      updated = e.copyWith(status: status);
      return updated!;
    }).toList();
    if (updated != null) _pushException(updated!);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Trip lifecycle: Request -> Approve -> Sign-Out (Gate) -> Active ->
  // Sign-In (Gate) -> Completed / Flagged
  // ---------------------------------------------------------------------

  Future<Trip> requestTrip({
    required String vehicleId,
    required String driverId,
    required String department,
    required List<String> passengers,
    String? cargoNotes,
    required String purpose,
    required String pickupPoint,
    required String destination,
  }) async {
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
    // Persist first so a rejected write surfaces as an error instead of a
    // phantom row that disappears on the next Realtime reload.
    await _persist('trips', tripToRow(trip));
    trips = [trip, ...trips];
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

  Future<void> approveTrip(String tripId, {required String approver}) async {
    final current = trips.firstWhereOrNull((t) => t.id == tripId);
    if (current == null || current.status != TripStatus.requested) {
      throw StateError('Only requested trips can be approved.');
    }
    final vehicle = vehicleById(current.vehicleId);
    final driver = driverById(current.driverId);
    if (vehicle == null || driver == null)
      throw StateError('The assigned vehicle or driver no longer exists.');
    if (vehicle.status != VehicleStatus.parked)
      throw StateError('The vehicle must be parked and available.');
    if (driver.status != DriverStatus.active)
      throw StateError('The assigned driver is not active.');
    if (DateTime.tryParse(driver.licenseExpiry)?.isBefore(DateTime.now()) ??
        true)
      throw StateError('The driver licence has expired.');
    if ((DateTime.tryParse(vehicle.insuranceExpiry)?.isBefore(DateTime.now()) ??
            true) ||
        (DateTime.tryParse(
              vehicle.roadworthinessExpiry,
            )?.isBefore(DateTime.now()) ??
            true)) {
      throw StateError('The vehicle compliance documents have expired.');
    }
    if (trips.any(
      (t) =>
          t.id != tripId &&
          t.vehicleId == vehicle.id &&
          (t.status == TripStatus.approved || t.status == TripStatus.active),
    )) {
      throw StateError('This vehicle already has an approved or active trip.');
    }
    Trip? updated;
    trips = trips.map((t) {
      if (t.id != tripId) return t;
      updated = t.copyWith(
        status: TripStatus.approved,
        approvedAt: DateTime.now().toIso8601String(),
      );
      return updated!;
    }).toList();
    if (updated != null)
      await _client.from('trips').upsert(tripToRow(updated!));
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

  Future<void> signOutTrip(
    String tripId, {
    required double odometer,
    required double fuelLevel,
    required String officerName,
  }) async {
    final trip = trips.firstWhereOrNull((t) => t.id == tripId);
    if (trip == null) return;
    // Simulate the tamper-proof GPS tracker's expected route distance for
    // this trip so the sign-in fraud check has an independent reference
    // point to compare the driver-reported odometer delta against.
    final simulatedGpsDistanceKm = (8 + _rng.nextInt(55)).toDouble();
    final updatedTrip = trip.copyWith(
      status: TripStatus.active,
      startedAt: DateTime.now().toIso8601String(),
      signOutOdometer: odometer,
      signOutFuelLevel: fuelLevel,
      signOutOfficerName: officerName,
      signOutTime: DateTime.now().toIso8601String(),
      gpsDistanceKm: simulatedGpsDistanceKm,
    );
    await _persist('trips', tripToRow(updatedTrip));
    trips = trips.map((t) => t.id == tripId ? updatedTrip : t).toList();

    final updatedVehicle = vehicles
        .firstWhereOrNull((v) => v.id == trip.vehicleId)
        ?.copyWith(status: VehicleStatus.active);
    if (updatedVehicle != null) {
      // Secondary write -- keep it best-effort so a vehicle-status hiccup
      // does not fail the whole sign-out after the trip already persisted.
      _pushVehicle(updatedVehicle);
      vehicles = vehicles
          .map((v) => v.id == trip.vehicleId ? updatedVehicle : v)
          .toList();
    }

    addAuditLog(
      userId: officerName,
      userRole: 'Gate Officer',
      action: 'Gate Sign-Out',
      entityType: 'Trip',
      entityId: tripId,
      details:
          'Vehicle dispatched at odometer $odometer km, fuel level $fuelLevel%.',
    );
    notifyListeners();
  }

  /// Ends a trip and runs the odometer-vs-GPS fraud check.
  /// [gpsDistanceKm] simulates the tamper-proof tracker reading; if omitted
  /// the trip's existing value (or the reported distance) is used.
  Future<void> signInTrip(
    String tripId, {
    required double odometer,
    required double fuelLevel,
    required String officerName,
    double? gpsDistanceKm,
  }) async {
    final trip = trips.firstWhereOrNull((t) => t.id == tripId);
    if (trip == null) return;
    final driver = driverById(trip.driverId);
    final startOdo = trip.signOutOdometer ?? odometer;
    final reportedDist = odometer - startOdo;
    final gpsDist = gpsDistanceKm ?? trip.gpsDistanceKm ?? reportedDist;

    final fraudDetected = gpsDist > 0 && reportedDist > gpsDist * 1.4;
    final newStatus = fraudDetected ? TripStatus.flagged : TripStatus.completed;

    final updatedTrip = trip.copyWith(
      status: newStatus,
      endedAt: DateTime.now().toIso8601String(),
      signInOdometer: odometer,
      signInFuelLevel: fuelLevel,
      signInOfficerName: officerName,
      signInTime: DateTime.now().toIso8601String(),
      gpsDistanceKm: gpsDist,
      routeDeviationFlagged: fraudDetected,
    );
    await _persist('trips', tripToRow(updatedTrip));
    trips = trips.map((t) => t.id == tripId ? updatedTrip : t).toList();

    final updatedVehicle = vehicles
        .firstWhereOrNull((v) => v.id == trip.vehicleId)
        ?.copyWith(currentOdometer: odometer, status: VehicleStatus.parked);
    if (updatedVehicle != null) {
      _pushVehicle(updatedVehicle);
      vehicles = vehicles
          .map((v) => v.id == trip.vehicleId ? updatedVehicle : v)
          .toList();
    }

    addAuditLog(
      userId: officerName,
      userRole: 'Gate Officer',
      action: 'Gate Sign-In',
      entityType: 'Trip',
      entityId: tripId,
      details:
          'Vehicle returned at odometer $odometer km (+${reportedDist.toStringAsFixed(1)} km), fuel level $fuelLevel%.',
    );

    if (fraudDetected) {
      await _raiseException(
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

  Future<FuelRequest> submitFuelRequest({
    required String vehicleId,
    required String driverId,
    required double odometer,
    required double requestedLiters,
    required double estimatedCost,
    required String stationName,
    String? receiptPhotoUrl,
    String? pumpPhotoUrl,
  }) async {
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
    await _persist('fuel_requests', fuelRequestToRow(req));
    fuelRequests = [req, ...fuelRequests];
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
    final relevant = trips.where(
      (t) =>
          t.vehicleId == vehicleId &&
          (t.status == TripStatus.completed ||
              t.status == TripStatus.flagged) &&
          t.gpsDistanceKm != null,
    );
    if (relevant.isEmpty)
      return 60; // reasonable default so div-by-zero can't happen
    final latest = relevant.reduce(
      (a, b) => (a.endedAt ?? '').compareTo(b.endedAt ?? '') > 0 ? a : b,
    );
    return latest.gpsDistanceKm ?? 60;
  }

  Future<void> approveFuelRequest(String id, {required String approver}) async {
    final req = fuelRequests.firstWhereOrNull((f) => f.id == id);
    final vehicle = req == null ? null : vehicleById(req.vehicleId);
    if (req == null || vehicle == null) return;
    if (req.status != 'Pending')
      throw StateError('Only pending fuel requests can be approved.');
    if (req.requestedLiters <= 0 ||
        req.requestedLiters > vehicle.tankCapacity) {
      throw StateError('Requested litres exceed the vehicle tank capacity.');
    }
    if (vehicle.currentMonthFuelUsed + req.requestedLiters >
        vehicle.monthlyFuelLimit) {
      throw StateError('Approval would exceed the monthly fuel allocation.');
    }

    final distance = _distanceSinceLastTrip(vehicle.id);
    final calculatedConsumption = req.requestedLiters > 0
        ? distance / req.requestedLiters
        : 0;
    final expected = vehicle.expectedFuelConsumption;
    final flagged = expected > 0 && calculatedConsumption < expected * 0.4;

    final updatedRequest = req.copyWith(
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
    );
    fuelRequests = fuelRequests
        .map((f) => f.id == id ? updatedRequest : f)
        .toList();
    await _client
        .from('fuel_requests')
        .upsert(fuelRequestToRow(updatedRequest));

    final updatedVehicle = vehicle.copyWith(
      currentMonthFuelUsed: vehicle.currentMonthFuelUsed + req.requestedLiters,
    );
    vehicles = vehicles
        .map((v) => v.id == vehicle.id ? updatedVehicle : v)
        .toList();
    await _client.from('vehicles').upsert(vehicleToRow(updatedVehicle));

    addAuditLog(
      userId: approver,
      userRole: 'Fleet Manager',
      action: 'Approved Fuel Request',
      entityType: 'FuelRequest',
      entityId: id,
      details:
          'Approved ${req.requestedLiters} L voucher ${req.voucherCode} for ${vehicle.registrationNumber}.',
    );

    if (flagged) {
      await _raiseException(
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

  Future<void> rejectFuelRequest(
    String id, {
    required String approver,
    required String reason,
  }) async {
    final current = fuelRequests.firstWhereOrNull((f) => f.id == id);
    if (current == null || current.status != 'Pending')
      throw StateError('Only pending fuel requests can be rejected.');
    if (reason.trim().isEmpty)
      throw StateError('A rejection reason is required.');
    FuelRequest? updated;
    fuelRequests = fuelRequests.map((f) {
      if (f.id != id) return f;
      updated = f.copyWith(status: 'Rejected');
      return updated!;
    }).toList();
    if (updated != null)
      await _client.from('fuel_requests').upsert(fuelRequestToRow(updated!));
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

  Future<MaintenanceRequest> submitMaintenanceRequest({
    required String vehicleId,
    required String driverId,
    required String category,
    required String description,
    required String severity,
    required double odometer,
    String? beforePhotoUrl,
  }) async {
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
    await _persist('maintenance_requests', maintenanceRequestToRow(req));
    maintenanceRequests = [req, ...maintenanceRequests];
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

  Future<void> approveMaintenanceRequest(
    String id, {
    required String approver,
    required double approvedAmount,
  }) async {
    final current = maintenanceRequests.firstWhereOrNull((m) => m.id == id);
    if (current == null || current.status != MaintenanceStatus.pending)
      throw StateError('Only pending maintenance requests can be approved.');
    if (approvedAmount <= 0)
      throw StateError('Approved amount must be greater than zero.');
    MaintenanceRequest? updated;
    maintenanceRequests = maintenanceRequests.map((m) {
      if (m.id != id) return m;
      updated = m.copyWith(
        status: MaintenanceStatus.approved,
        approvedAmount: approvedAmount,
      );
      return updated!;
    }).toList();
    if (updated != null)
      await _client
          .from('maintenance_requests')
          .upsert(maintenanceRequestToRow(updated!));
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

  Future<void> dispatchToGarage(
    String id, {
    required String dispatcher,
    required String garageName,
  }) async {
    final current = maintenanceRequests.firstWhereOrNull((m) => m.id == id);
    if (current == null || current.status != MaintenanceStatus.approved)
      throw StateError('Only approved maintenance can be dispatched.');
    if (garageName.trim().isEmpty) throw StateError('Garage name is required.');
    MaintenanceRequest? updated;
    maintenanceRequests = maintenanceRequests.map((m) {
      if (m.id != id) return m;
      updated = m.copyWith(
        status: MaintenanceStatus.inGarage,
        garageName: garageName,
      );
      return updated!;
    }).toList();
    if (updated != null)
      await _client
          .from('maintenance_requests')
          .upsert(maintenanceRequestToRow(updated!));
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

  Future<void> completeMaintenanceRequest(
    String id, {
    required String completedBy,
    required double invoiceAmount,
    String? invoicePhotoUrl,
    String? afterPhotoUrl,
    String? completionNotes,
    bool testDrivePassed = true,
  }) async {
    final current = maintenanceRequests.firstWhereOrNull((m) => m.id == id);
    if (current == null || current.status != MaintenanceStatus.inGarage)
      throw StateError(
        'Only maintenance currently in a garage can be completed.',
      );
    if (invoiceAmount <= 0)
      throw StateError('Invoice amount must be greater than zero.');
    MaintenanceRequest? updated;
    maintenanceRequests = maintenanceRequests.map((m) {
      if (m.id != id) return m;
      updated = m.copyWith(
        status: MaintenanceStatus.completed,
        invoiceAmount: invoiceAmount,
        invoicePhotoUrl: invoicePhotoUrl,
        afterPhotoUrl: afterPhotoUrl,
        completionNotes: completionNotes,
        testDrivePassed: testDrivePassed,
      );
      return updated!;
    }).toList();
    if (updated != null)
      await _client
          .from('maintenance_requests')
          .upsert(maintenanceRequestToRow(updated!));

    final req = updated;
    if (req != null &&
        req.approvedAmount != null &&
        (invoiceAmount - req.approvedAmount!).abs() >
            req.approvedAmount! * 0.15) {
      await _raiseException(
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
      details:
          completionNotes ??
          'Repair marked complete, invoice \$${invoiceAmount.toStringAsFixed(2)}.',
    );
    notifyListeners();
  }

  Future<void> verifyMaintenanceRequest(
    String id, {
    required String verifier,
  }) async {
    final current = maintenanceRequests.firstWhereOrNull((m) => m.id == id);
    if (current == null || current.status != MaintenanceStatus.completed)
      throw StateError('Only completed maintenance can be verified.');
    if (current.testDrivePassed != true)
      throw StateError('The test drive must pass before verification.');
    MaintenanceRequest? updated;
    maintenanceRequests = maintenanceRequests.map((m) {
      if (m.id != id) return m;
      updated = m.copyWith(status: MaintenanceStatus.verified);
      return updated!;
    }).toList();
    if (updated != null)
      await _client
          .from('maintenance_requests')
          .upsert(maintenanceRequestToRow(updated!));
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

  Future<Inspection> submitInspection({
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
  }) async {
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
    await _persist('inspections', inspectionToRow(insp));
    inspections = [insp, ...inspections];
    final driver = driverById(driverId);
    addAuditLog(
      userId: driver?.name ?? driverId,
      userRole: 'Driver',
      action: '$type Inspection Submitted',
      entityType: 'Inspection',
      entityId: insp.id,
      details: insp.allPassed
          ? 'All checklist items passed.'
          : 'One or more checklist items failed: ${notes ?? ''}',
    );
    if (!insp.allPassed) {
      await _raiseException(
        type: 'Trip',
        severity: ExceptionSeverity.medium,
        title: '$type Inspection Failed Checklist Item(s)',
        description:
            'Driver ${driver?.name ?? driverId} reported a failed vehicle condition item during $type inspection. '
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

  Future<Incident> reportIncident({
    required String category,
    required String vehicleId,
    required String driverId,
    required String description,
    required String location,
    String? photoUrl,
  }) async {
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
    await _persist('incidents', incidentToRow(incident));
    incidents = [incident, ...incidents];
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

  Future<void> updateIncidentStatus(
    String id,
    String status, {
    required String updatedBy,
  }) async {
    const transitions = <String, Set<String>>{
      'Pending': {'Under Investigation'},
      'Under Investigation': {'Resolved'},
    };
    final current = incidents.firstWhereOrNull((i) => i.id == id);
    if (current == null) throw StateError('Incident not found.');
    if (!(transitions[current.status]?.contains(status) ?? false)) {
      throw StateError(
        'Invalid incident transition from ${current.status} to $status.',
      );
    }
    Incident? updated;
    incidents = incidents.map((i) {
      if (i.id != id) return i;
      updated = i.copyWith(status: status);
      return updated!;
    }).toList();
    if (updated != null)
      await _client.from('incidents').upsert(incidentToRow(updated!));
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

  Future<void> updatePolicyRuleValue(
    String id,
    String newValue, {
    required String updatedBy,
  }) async {
    if (newValue.trim().isEmpty)
      throw StateError('Policy value cannot be empty.');
    final old = policyRules.firstWhereOrNull((p) => p.id == id);
    PolicyRule? updated;
    policyRules = policyRules.map((p) {
      if (p.id != id) return p;
      updated = p.copyWith(value: newValue);
      return updated!;
    }).toList();
    if (updated != null)
      await _client.from('policy_rules').upsert(policyRuleToRow(updated!));
    addAuditLog(
      userId: updatedBy,
      userRole: 'System Admin',
      action: 'Rule Change',
      entityType: 'PolicyRule',
      entityId: id,
      details:
          'Updated ${old?.name ?? id} value from "${old?.value}" to "$newValue".',
    );
    notifyListeners();
  }

  void adjustSparePartStock(String id, int delta, {required String updatedBy}) {
    SparePart? updated;
    spareParts = spareParts.map((s) {
      if (s.id != id) return s;
      updated = s.copyWith(
        stockQty: (s.stockQty + delta).clamp(0, 1 << 30).toInt(),
      );
      return updated!;
    }).toList();
    if (updated != null) _pushSparePart(updated!);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Vehicle status / tracker
  // ---------------------------------------------------------------------

  void setVehicleStatus(String id, VehicleStatus status) {
    Vehicle? updated;
    vehicles = vehicles.map((v) {
      if (v.id != id) return v;
      updated = v.copyWith(status: status);
      return updated!;
    }).toList();
    if (updated != null) _pushVehicle(updated!);
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
