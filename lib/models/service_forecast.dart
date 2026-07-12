import 'maintenance_request.dart';
import 'trip.dart';
import 'vehicle.dart';

class ComponentForecast {
  final String name;
  final double intervalKm;
  final double kmSinceService;
  final double remainingKm;
  final DateTime projectedDate;
  const ComponentForecast(this.name, this.intervalKm, this.kmSinceService,
      this.remainingKm, this.projectedDate);
  double get wearRatio => (kmSinceService / intervalKm).clamp(0, 1.5).toDouble();
  bool get overdue => remainingKm <= 0;
}

class VehicleServiceForecast {
  final Vehicle vehicle;
  final double averageDailyKm;
  final List<ComponentForecast> components;
  const VehicleServiceForecast(this.vehicle, this.averageDailyKm, this.components);
  bool get hasOverdueComponent => components.any((c) => c.overdue);
}

class ServiceForecastEngine {
  static const intervals = <String, double>{
    'Engine Oil & Filter': 5000,
    'Brake Pads & Calipers': 15000,
    'Air & Fuel Filters': 10000,
    'Tyre Wear & Rotation': 40000,
  };

  static VehicleServiceForecast calculate(Vehicle vehicle, List<Trip> trips,
      List<MaintenanceRequest> maintenance, {double scenarioKm = 0}) {
    final completed = trips.where((t) => t.vehicleId == vehicle.id && t.endedAt != null).toList();
    final totalGpsKm = completed.fold<double>(0, (s, t) => s + (t.gpsDistanceKm ?? 0));
    final dates = completed.map((t) => DateTime.tryParse(t.endedAt!)).whereType<DateTime>().toList();
    final observedDays = dates.isEmpty ? 30 : DateTime.now().difference(dates.reduce((a, b) => a.isBefore(b) ? a : b)).inDays.clamp(1, 365);
    final stress = _stressMultiplier(vehicle.assignedDepartment, vehicle.type);
    final dailyKm = ((totalGpsKm > 0 ? totalGpsKm / observedDays : vehicle.currentOdometer / 365) * stress).clamp(1.0, 1000.0).toDouble();
    final projectedOdometer = vehicle.currentOdometer + scenarioKm;
    final components = intervals.entries.map((entry) {
      final last = _lastServiceOdometer(vehicle.id, entry.key, maintenance);
      final since = (projectedOdometer - last).clamp(0.0, double.infinity).toDouble();
      final remaining = entry.value - since;
      final days = remaining <= 0 ? 0 : (remaining / dailyKm).ceil();
      return ComponentForecast(entry.key, entry.value, since, remaining, DateTime.now().add(Duration(days: days)));
    }).toList();
    return VehicleServiceForecast(vehicle, dailyKm, components);
  }

  static double _lastServiceOdometer(String vehicleId, String component,
      List<MaintenanceRequest> records) {
    final words = component.toLowerCase().split(' ');
    final matches = records.where((m) => m.vehicleId == vehicleId &&
      m.status.name == 'verified' && words.any((w) => w.length > 3 &&
      '${m.category} ${m.description} ${m.completionNotes ?? ''}'.toLowerCase().contains(w))).toList();
    if (matches.isEmpty) return 0;
    return matches.map((m) => m.odometer).reduce((a, b) => a > b ? a : b);
  }

  static double _stressMultiplier(String department, String type) {
    final value = '$department $type'.toLowerCase();
    if (value.contains('emergency')) return 1.35;
    if (value.contains('shuttle') || value.contains('field')) return 1.2;
    return 1.0;
  }
}
