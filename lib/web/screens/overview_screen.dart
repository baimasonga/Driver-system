import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/fleet_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/section_header.dart';
import '../../widgets/severity_badge.dart';
import '../../widgets/stat_card.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();

    final activeVehicles = data.vehicles.where((v) => v.status == VehicleStatus.active).length;
    final activeTrips = data.trips.where((t) => t.status == TripStatus.active).length;
    final openExceptions = data.exceptions.where((e) => e.status != 'Resolved').length;
    final pendingFuel = data.fuelRequests.where((f) => f.status == 'Pending').length;
    final pendingMaintenance = data.maintenanceRequests.where((m) => m.status == MaintenanceStatus.pending).length;
    final monthlyFuelUsed = data.vehicles.fold<double>(0, (sum, v) => sum + v.currentMonthFuelUsed);
    final fuelVarianceFlags = data.fuelRequests.where((f) => f.varianceFlagged == true).length;
    final lowStockParts = data.spareParts.where((p) => p.stockQty <= p.reorderLevel).length;
    final partSwaps = data.maintenancePartMovements.length;
    final openWorkOrders = data.maintenanceRequests.where((m) => m.status != MaintenanceStatus.verified).length;
    final overdueServiceVehicles = data.vehicles.where((v) =>
      ServiceForecastEngine.calculate(v, data.trips, data.maintenanceRequests).hasOverdueComponent).length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (overdueServiceVehicles > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.red500.withOpacity(.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.red500.withOpacity(.55))),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.red500),
                const SizedBox(width: 12),
                Expanded(child: Text('$overdueServiceVehicles vehicle(s) have components beyond standard service intervals. Open Service Forecast and create preventive work orders.', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          LayoutBuilder(builder: (context, constraints) {
            final cross = constraints.maxWidth > 900 ? 5 : (constraints.maxWidth > 560 ? 3 : 2);
            return GridView.count(
              crossAxisCount: cross,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                StatCard(label: 'Active Vehicles', value: '$activeVehicles', icon: Icons.directions_car, accent: AppColors.green500),
                StatCard(label: 'Trips In Progress', value: '$activeTrips', icon: Icons.route, accent: AppColors.blue500),
                StatCard(label: 'Open Exceptions', value: '$openExceptions', icon: Icons.gpp_maybe, accent: AppColors.red500),
                StatCard(label: 'Pending Fuel', value: '$pendingFuel', icon: Icons.local_gas_station, accent: AppColors.amber500),
                StatCard(label: 'Pending Repairs', value: '$pendingMaintenance', icon: Icons.build, accent: AppColors.orange500),
              ],
            );
          }),
          const SizedBox(height: 12),
          StatCard(
            label: 'Fleet-wide Fuel Used This Month',
            value: formatLiters(monthlyFuelUsed),
            icon: Icons.speed,
            accent: AppColors.amber500,
            sublabel: '${data.vehicles.length} vehicles tracked',
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Operational Controls', icon: Icons.fact_check_outlined),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final cross = constraints.maxWidth > 800 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cross,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.9,
              children: [
                StatCard(label: 'Fuel Audit Flags', value: '$fuelVarianceFlags', icon: Icons.receipt_long, accent: AppColors.red500, sublabel: 'Receipt, cost and km/L exceptions'),
                StatCard(label: 'Open Work Orders', value: '$openWorkOrders', icon: Icons.assignment_outlined, accent: AppColors.orange500, sublabel: 'Diagnosis through verification'),
                StatCard(label: 'Low-stock Parts', value: '$lowStockParts', icon: Icons.inventory_2_outlined, accent: AppColors.amber500, sublabel: 'At or below reorder level'),
                StatCard(label: 'Serialized Part Swaps', value: '$partSwaps', icon: Icons.swap_horiz, accent: AppColors.blue500, sublabel: 'Removed vs installed register'),
              ],
            );
          }),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _RecentExceptions(exceptions: data.exceptions.take(5).toList(), vehicles: data.vehicles)),
              const SizedBox(width: 16),
              Expanded(child: _RecentAudit(logs: data.auditLogs.take(6).toList())),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentExceptions extends StatelessWidget {
  final List<ExceptionRecord> exceptions;
  final List<Vehicle> vehicles;
  const _RecentExceptions({required this.exceptions, required this.vehicles});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neutral900,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutral800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Latest Exceptions', icon: Icons.gpp_maybe_outlined),
          if (exceptions.isEmpty) const EmptyState(message: 'No exceptions raised.'),
          for (final e in exceptions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SeverityBadge(severity: e.severity.label),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.title,
                            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(formatDateTime(e.timestamp), style: const TextStyle(color: AppColors.neutral400, fontSize: 10.5)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentAudit extends StatelessWidget {
  final List<AuditLog> logs;
  const _RecentAudit({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neutral900,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutral800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Blackbox Trail', icon: Icons.security_outlined),
          if (logs.isEmpty) const EmptyState(message: 'No activity recorded yet.'),
          for (final l in logs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.action, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(l.details, style: const TextStyle(color: AppColors.neutral400, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('${l.userId} · ${formatDateTime(l.timestamp)}', style: const TextStyle(color: AppColors.neutral700, fontSize: 10)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
