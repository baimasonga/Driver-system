import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/driver_session.dart';
import '../../state/fleet_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_badge.dart';

class TripsTab extends StatelessWidget {
  const TripsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();
    final session = context.watch<DriverSession>();
    final myTrips = data.trips.where((t) => t.driverId == session.driverId).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRequestSheet(context, data, session.driverId),
        icon: const Icon(Icons.add),
        label: const Text('Request Trip'),
      ),
      body: myTrips.isEmpty
          ? const Center(child: Text('No trips yet. Tap "Request Trip" to get started.', style: TextStyle(color: AppColors.neutral400)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: myTrips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final t = myTrips[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.neutral900, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.neutral800)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(t.tripRequestNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5))),
                          StatusBadge(label: t.status.label),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${t.pickupPoint} → ${t.destination}', style: const TextStyle(color: AppColors.neutral300, fontSize: 12)),
                      const SizedBox(height: 3),
                      Text(formatDateTime(t.requestedAt), style: const TextStyle(color: AppColors.neutral700, fontSize: 10.5)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showRequestSheet(BuildContext context, FleetDataProvider data, String driverId) {
    final vehicle = data.vehicleForDriver(driverId);
    final purposeController = TextEditingController();
    final destinationController = TextEditingController();
    final pickupController = TextEditingController(text: vehicle?.assignedDepartment ?? 'HQ Depot');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.neutral900,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('New Trip Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 16),
              TextField(controller: pickupController, decoration: const InputDecoration(labelText: 'Pickup point')),
              const SizedBox(height: 12),
              TextField(controller: destinationController, decoration: const InputDecoration(labelText: 'Destination')),
              const SizedBox(height: 12),
              TextField(controller: purposeController, decoration: const InputDecoration(labelText: 'Purpose of trip'), maxLines: 2),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (vehicle == null) return;
                    data.requestTrip(
                      vehicleId: vehicle.id,
                      driverId: driverId,
                      department: vehicle.assignedDepartment,
                      passengers: const [],
                      purpose: purposeController.text.isEmpty ? 'Operational trip' : purposeController.text,
                      pickupPoint: pickupController.text,
                      destination: destinationController.text.isEmpty ? 'Unspecified' : destinationController.text,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Submit Request'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
