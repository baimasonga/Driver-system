import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/fleet_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_badge.dart';
import '../dialogs/vehicle_form_dialog.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => showVehicleFormDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Vehicle'),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: data.vehicles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final v = data.vehicles[i];
              final driver = data.driverById(v.assignedDriverId);
              final insuranceExpired = isExpired(v.insuranceExpiry);
              final roadworthyExpired = isExpired(v.roadworthinessExpiry);
              final fuelPct = v.monthlyFuelLimit > 0
                  ? (v.currentMonthFuelUsed / v.monthlyFuelLimit).clamp(0, 1.0)
                  : 0.0;

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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.amber500.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.directions_car,
                            color: AppColors.amber500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${v.make} ${v.model}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${v.registrationNumber} · ${v.type} · ${v.year}',
                                style: const TextStyle(
                                  color: AppColors.neutral400,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(label: v.status.label),
                        PopupMenuButton<String>(
                          onSelected: (action) async {
                            if (action == 'edit') {
                              await showVehicleFormDialog(context, v);
                            } else {
                              try {
                                await data.deleteVehicle(
                                  v.id,
                                  deletedBy: 'Fleet Manager',
                                );
                              } catch (e) {
                                if (context.mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceFirst(
                                          'Bad state: ',
                                          '',
                                        ),
                                      ),
                                    ),
                                  );
                              }
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: [
                        _Fact(
                          label: 'Driver',
                          value: driver?.name ?? 'Unassigned',
                        ),
                        _Fact(
                          label: 'Odometer',
                          value: formatKm(v.currentOdometer),
                        ),
                        _Fact(label: 'Department', value: v.assignedDepartment),
                        _Fact(
                          label: 'GPS Tracker',
                          value: v.gpsTrackerId,
                          valueColor: AppColors.statusColor(
                            v.trackerStatus.label,
                          ),
                        ),
                        _Fact(
                          label: 'Last Location',
                          value: v.lastGpsLocation.address,
                        ),
                        _Fact(
                          label: 'Insurance',
                          value: formatDate(v.insuranceExpiry),
                          valueColor: insuranceExpired
                              ? AppColors.red500
                              : AppColors.neutral100,
                        ),
                        _Fact(
                          label: 'Roadworthiness',
                          value: formatDate(v.roadworthinessExpiry),
                          valueColor: roadworthyExpired
                              ? AppColors.red500
                              : AppColors.neutral100,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text(
                          'Monthly Fuel',
                          style: TextStyle(
                            color: AppColors.neutral400,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${v.currentMonthFuelUsed.toStringAsFixed(0)} / ${v.monthlyFuelLimit.toStringAsFixed(0)} L',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: fuelPct.toDouble(),
                        minHeight: 6,
                        backgroundColor: AppColors.neutral800,
                        color: fuelPct > 0.9
                            ? AppColors.red500
                            : AppColors.amber500,
                      ),
                    ),
                    if (v.trackerStatus == TrackerStatus.tampered ||
                        v.trackerStatus == TrackerStatus.offline) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.red500.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.red500.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.red500,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                v.trackerStatus == TrackerStatus.tampered
                                    ? 'GPS tracker reports tamper signal — verify vehicle location manually.'
                                    : 'GPS tracker offline — last known location may be stale.',
                                style: const TextStyle(
                                  color: AppColors.red500,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Fact({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.neutral700,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.neutral100,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
