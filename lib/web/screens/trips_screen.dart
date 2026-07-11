import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/fleet_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_badge.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();
    final filters = ['All', ...TripStatus.values.map((e) => e.label)];
    final trips = _filter == 'All' ? data.trips : data.trips.where((t) => t.status.label == _filter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final f = filters[i];
              final selected = f == _filter;
              return ChoiceChip(
                label: Text(f),
                selected: selected,
                onSelected: (_) => setState(() => _filter = f),
                selectedColor: AppColors.amber500,
                labelStyle: TextStyle(color: selected ? AppColors.neutral950 : AppColors.neutral300, fontWeight: FontWeight.w700, fontSize: 11.5),
                backgroundColor: AppColors.neutral900,
                side: BorderSide(color: selected ? AppColors.amber500 : AppColors.neutral800),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: trips.isEmpty
              ? const Center(child: Text('No trips in this state.', style: TextStyle(color: AppColors.neutral400)))
              : ListView.separated(
                  itemCount: trips.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final t = trips[i];
                    final vehicle = data.vehicleById(t.vehicleId);
                    final driver = data.driverById(t.driverId);
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.neutral900,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: t.status == TripStatus.flagged ? AppColors.red500.withOpacity(0.5) : AppColors.neutral800),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(t.tripRequestNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                              StatusBadge(label: t.status.label),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${vehicle?.registrationNumber ?? t.vehicleId} · ${driver?.name ?? t.driverId}',
                              style: const TextStyle(color: AppColors.neutral400, fontSize: 11.5)),
                          const SizedBox(height: 10),
                          Text('${t.pickupPoint}  →  ${t.destination}', style: const TextStyle(color: AppColors.neutral100, fontSize: 12.5)),
                          const SizedBox(height: 2),
                          Text(t.purpose, style: const TextStyle(color: AppColors.neutral400, fontSize: 11.5)),
                          if (t.signOutOdometer != null || t.signInOdometer != null) ...[
                            const SizedBox(height: 10),
                            Wrap(spacing: 20, runSpacing: 6, children: [
                              if (t.signOutOdometer != null) _kv('Sign-out Odo', formatKm(t.signOutOdometer!)),
                              if (t.signInOdometer != null) _kv('Sign-in Odo', formatKm(t.signInOdometer!)),
                              if (t.gpsDistanceKm != null) _kv('GPS Distance', '${t.gpsDistanceKm!.toStringAsFixed(1)} km'),
                            ]),
                          ],
                          if (t.status == TripStatus.flagged) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.red500.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: const Row(
                                children: [
                                  Icon(Icons.report_problem_outlined, color: AppColors.red500, size: 15),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text('Odometer distance exceeds GPS-verified distance. Review in Exceptions.',
                                        style: TextStyle(color: AppColors.red500, fontSize: 11.5)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (t.status == TripStatus.requested) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => data.approveTrip(t.id, approver: 'M. Bangura (Fleet Mgr)'),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Approve Trip'),
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

  Widget _kv(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.neutral700, fontSize: 9.5, fontWeight: FontWeight.w700)),
        Text(value, style: const TextStyle(color: AppColors.neutral100, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
