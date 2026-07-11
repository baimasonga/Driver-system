import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/driver_session.dart';
import '../../state/fleet_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_badge.dart';
import '../widgets/trip_sign_dialog.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();
    final session = context.watch<DriverSession>();
    final driver = data.driverById(session.driverId);
    if (driver == null) return const SizedBox();

    final vehicle = data.vehicleForDriver(driver.id);
    final activeTrip = data.activeTripForDriver(driver.id);
    final pendingTrip = data.pendingTripForDriver(driver.id);
    final myExceptions = data.exceptions.where((e) => e.driverId == driver.id && e.status != 'Resolved').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.neutral900, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.neutral800)),
          child: Row(
            children: [
              CircleAvatar(radius: 24, backgroundImage: NetworkImage(driver.photoUrl)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                    Text(driver.staffNumber, style: const TextStyle(color: AppColors.neutral400, fontSize: 11.5)),
                  ],
                ),
              ),
              StatusBadge(
                label: 'Risk ${driver.riskScore}',
                color: driver.riskScore > 50 ? AppColors.red500 : AppColors.green500,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (vehicle != null) _VehicleCard(vehicle: vehicle),
        const SizedBox(height: 14),
        if (activeTrip != null)
          _ActiveTripCard(trip: activeTrip)
        else if (pendingTrip != null)
          _PendingTripCard(trip: pendingTrip)
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.neutral900, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.neutral800)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.neutral400, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text('No active or assigned trip. Request a new trip from the Trips tab.', style: TextStyle(color: AppColors.neutral400, fontSize: 12.5))),
              ],
            ),
          ),
        if (myExceptions.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('OPEN ALERTS ON YOUR FILE', style: TextStyle(color: AppColors.neutral400, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          for (final e in myExceptions)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.red500.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.red500.withOpacity(0.3))),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.red500, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.title, style: const TextStyle(color: AppColors.red500, fontSize: 12, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.neutral900, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.neutral800)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car, size: 15, color: AppColors.amber500),
              const SizedBox(width: 6),
              const Text('ASSIGNED VEHICLE', style: TextStyle(color: AppColors.neutral400, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
              const Spacer(),
              Text(vehicle.registrationNumber, style: const TextStyle(color: AppColors.green500, fontWeight: FontWeight.w800, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${vehicle.make} ${vehicle.model}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _miniStat('Odometer', formatKm(vehicle.currentOdometer))),
              const SizedBox(width: 8),
              Expanded(child: _miniStat('Fuel Tank', '${vehicle.tankCapacity.toStringAsFixed(0)} L cap')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.neutral950, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.neutral400, fontSize: 10)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
          ],
        ),
      );
}

class _ActiveTripCard extends StatelessWidget {
  final Trip trip;
  const _ActiveTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.green500.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.green500.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.navigation, size: 14, color: AppColors.green500),
              const SizedBox(width: 6),
              const Text('TRIP IN PROGRESS', style: TextStyle(color: AppColors.green500, fontSize: 11, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(trip.tripRequestNumber, style: const TextStyle(color: AppColors.neutral400, fontSize: 10.5)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Destination', style: TextStyle(color: AppColors.neutral400, fontSize: 11)),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: AppColors.red500),
              const SizedBox(width: 4),
              Expanded(child: Text(trip.destination, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5))),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.red500, foregroundColor: Colors.white),
              onPressed: () => showTripSignDialog(context, tripId: trip.id, isSignIn: true),
              icon: const Icon(Icons.flag_outlined, size: 16),
              label: const Text('Complete Trip (Gate Sign-In)'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingTripCard extends StatelessWidget {
  final Trip trip;
  const _PendingTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amber500.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.amber500.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.amber500),
              const SizedBox(width: 6),
              const Text('TRIP APPROVED', style: TextStyle(color: AppColors.amber500, fontSize: 11, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(trip.tripRequestNumber, style: const TextStyle(color: AppColors.neutral400, fontSize: 10.5)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Target Destination', style: TextStyle(color: AppColors.neutral400, fontSize: 11)),
          Text(trip.destination, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => showTripSignDialog(context, tripId: trip.id, isSignIn: false),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Start Trip (Gate Sign-Out)'),
            ),
          ),
        ],
      ),
    );
  }
}
