import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/fleet_data_provider.dart';
import '../../state/auth_provider.dart';
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
    final trips = _filter == 'All'
        ? data.trips
        : data.trips.where((t) => t.status.label == _filter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
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
                labelStyle: TextStyle(
                  color: selected ? AppColors.neutral950 : AppColors.neutral300,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
                backgroundColor: AppColors.neutral900,
                side: BorderSide(
                  color: selected ? AppColors.amber500 : AppColors.neutral800,
                ),
              );
            },
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: data.vehicles.isEmpty || data.drivers.isEmpty
                  ? null
                  : () => _createTrip(context, data),
              icon: const Icon(Icons.add, size: 17),
              label: const Text('Create Trip'),
            ),
          ],
        ),
        if (data.vehicles.isEmpty || data.drivers.isEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.amber500.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.amber500.withOpacity(0.3))),
            child: const Text('Create at least one vehicle and one active driver before creating a trip.', style: TextStyle(color: AppColors.amber500, fontSize: 12)),
          ),
        ],
        const SizedBox(height: 16),
        Expanded(
          child: trips.isEmpty
              ? const Center(
                  child: Text(
                    'No trips in this state.',
                    style: TextStyle(color: AppColors.neutral400),
                  ),
                )
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
                        border: Border.all(
                          color: t.status == TripStatus.flagged
                              ? AppColors.red500.withOpacity(0.5)
                              : AppColors.neutral800,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.tripRequestNumber,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              StatusBadge(label: t.status.label),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${vehicle?.registrationNumber ?? t.vehicleId} · ${driver?.name ?? t.driverId}',
                            style: const TextStyle(
                              color: AppColors.neutral400,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${t.pickupPoint}  →  ${t.destination}',
                            style: const TextStyle(
                              color: AppColors.neutral100,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.purpose,
                            style: const TextStyle(
                              color: AppColors.neutral400,
                              fontSize: 11.5,
                            ),
                          ),
                          if (t.signOutOdometer != null ||
                              t.signInOdometer != null) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 20,
                              runSpacing: 6,
                              children: [
                                if (t.signOutOdometer != null)
                                  _kv(
                                    'Sign-out Odo',
                                    formatKm(t.signOutOdometer!),
                                  ),
                                if (t.signInOdometer != null)
                                  _kv(
                                    'Sign-in Odo',
                                    formatKm(t.signInOdometer!),
                                  ),
                                if (t.gpsDistanceKm != null)
                                  _kv(
                                    'GPS Distance',
                                    '${t.gpsDistanceKm!.toStringAsFixed(1)} km',
                                  ),
                              ],
                            ),
                          ],
                          if (t.status == TripStatus.flagged) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.red500.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.report_problem_outlined,
                                    color: AppColors.red500,
                                    size: 15,
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Odometer distance exceeds GPS-verified distance. Review in Exceptions.',
                                      style: TextStyle(
                                        color: AppColors.red500,
                                        fontSize: 11.5,
                                      ),
                                    ),
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
                                onPressed: () async {
                                  try {
                                    final name =
                                        context
                                            .read<AuthProvider>()
                                            .profile
                                            ?.fullName ??
                                        'Fleet Manager';
                                    await data.approveTrip(
                                      t.id,
                                      approver: name,
                                    );
                                  } catch (e) {
                                    if (context.mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                                },
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
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.neutral700,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.neutral100,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  void _createTrip(BuildContext context, FleetDataProvider data) {
    String vehicleId = data.vehicles.first.id;
    String driverId = data.drivers.first.id;
    final department = TextEditingController();
    final pickup = TextEditingController();
    final destination = TextEditingController();
    final purpose = TextEditingController();
    final passengers = TextEditingController();
    final cargo = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Trip Assignment'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: vehicleId,
                    items: data.vehicles.map((v) => DropdownMenuItem(value: v.id, child: Text('${v.registrationNumber} · ${v.make} ${v.model}'))).toList(),
                    onChanged: (v) => setDialogState(() => vehicleId = v!),
                    decoration: const InputDecoration(labelText: 'Vehicle'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: driverId,
                    items: data.drivers.map((d) => DropdownMenuItem(value: d.id, child: Text('${d.name} · ${d.staffNumber}'))).toList(),
                    onChanged: (v) => setDialogState(() => driverId = v!),
                    decoration: const InputDecoration(labelText: 'Driver'),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: department, decoration: const InputDecoration(labelText: 'Requesting department')),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: TextField(controller: pickup, decoration: const InputDecoration(labelText: 'Pickup point'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: destination, decoration: const InputDecoration(labelText: 'Destination'))),
                  ]),
                  const SizedBox(height: 10),
                  TextField(controller: purpose, maxLines: 2, decoration: const InputDecoration(labelText: 'Trip purpose')),
                  const SizedBox(height: 10),
                  TextField(controller: passengers, decoration: const InputDecoration(labelText: 'Passengers (comma separated)')),
                  const SizedBox(height: 10),
                  TextField(controller: cargo, decoration: const InputDecoration(labelText: 'Cargo/notes (optional)')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(onPressed: () async {
              if ([department.text, pickup.text, destination.text, purpose.text].any((v) => v.trim().isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department, pickup, destination and purpose are required.')));
                return;
              }
              try {
                await data.requestTrip(
                  vehicleId: vehicleId, driverId: driverId, department: department.text.trim(),
                  passengers: passengers.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  cargoNotes: cargo.text.trim().isEmpty ? null : cargo.text.trim(), purpose: purpose.text.trim(),
                  pickupPoint: pickup.text.trim(), destination: destination.text.trim(),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))));
              }
            }, child: const Text('Create Request')),
          ],
        ),
      ),
    );
  }
}
