import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/fleet_data_provider.dart';
import '../../theme/app_theme.dart';

Future<void> showTripSignDialog(BuildContext context, {required String tripId, required bool isSignIn}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.neutral900,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => _TripSignSheet(tripId: tripId, isSignIn: isSignIn),
  );
}

class _TripSignSheet extends StatefulWidget {
  final String tripId;
  final bool isSignIn;
  const _TripSignSheet({required this.tripId, required this.isSignIn});

  @override
  State<_TripSignSheet> createState() => _TripSignSheetState();
}

class _TripSignSheetState extends State<_TripSignSheet> {
  late final TextEditingController _odoController;
  late final TextEditingController _officerController;
  double _fuelLevel = 80;

  @override
  void initState() {
    super.initState();
    final data = context.read<FleetDataProvider>();
    final trip = data.trips.firstWhere((t) => t.id == widget.tripId);
    final vehicle = data.vehicleById(trip.vehicleId);
    final startOdo = trip.signOutOdometer ?? vehicle?.currentOdometer ?? 0;
    final suggested = widget.isSignIn ? startOdo + (trip.gpsDistanceKm ?? 20) : (vehicle?.currentOdometer ?? 0);
    _odoController = TextEditingController(text: suggested.toStringAsFixed(0));
    _officerController = TextEditingController(text: 'Self-Service (Driver App)');
    _fuelLevel = widget.isSignIn ? 45 : 80;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();
    final trip = data.trips.firstWhere((t) => t.id == widget.tripId);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isSignIn ? 'Gate Sign-In · Complete Trip' : 'Gate Sign-Out · Start Trip',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(trip.tripRequestNumber, style: const TextStyle(color: AppColors.neutral400, fontSize: 12)),
            const SizedBox(height: 18),
            TextField(
              controller: _odoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Odometer reading (KM)'),
            ),
            const SizedBox(height: 14),
            Text('Fuel level: ${_fuelLevel.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.neutral300, fontSize: 12)),
            Slider(
              value: _fuelLevel,
              min: 0,
              max: 100,
              activeColor: AppColors.amber500,
              onChanged: (v) => setState(() => _fuelLevel = v),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _officerController,
              decoration: const InputDecoration(labelText: 'Signed off by'),
            ),
            if (widget.isSignIn && trip.gpsDistanceKm != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.blue500.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  'GPS tracker recorded ${trip.gpsDistanceKm!.toStringAsFixed(1)} km for this route. Your odometer entry will be cross-checked automatically.',
                  style: const TextStyle(color: AppColors.blue500, fontSize: 11.5),
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final odo = double.tryParse(_odoController.text.trim());
                  final minimumOdometer = trip.signOutOdometer ?? data.vehicleById(trip.vehicleId)?.currentOdometer ?? 0;
                  final officer = _officerController.text.trim();
                  if (odo == null || odo < minimumOdometer || officer.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid odometer reading and signing officer.')),
                    );
                    return;
                  }
                  if (widget.isSignIn) {
                    data.signInTrip(
                      trip.id,
                      odometer: odo,
                      fuelLevel: _fuelLevel,
                      officerName: officer,
                    );
                  } else {
                    data.signOutTrip(
                      trip.id,
                      odometer: odo,
                      fuelLevel: _fuelLevel,
                      officerName: officer,
                    );
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(widget.isSignIn ? 'Trip completed and submitted.' : 'Trip started. Drive safe.')),
                  );
                },
                child: Text(widget.isSignIn ? 'Submit & Complete Trip' : 'Confirm & Start Trip'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
