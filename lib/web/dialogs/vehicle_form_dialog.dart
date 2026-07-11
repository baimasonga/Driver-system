import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/fleet_data_provider.dart';

Future<void> showVehicleFormDialog(
  BuildContext context, [
  Vehicle? existing,
]) async {
  final data = context.read<FleetDataProvider>();
  final formKey = GlobalKey<FormState>();
  final registration = TextEditingController(
    text: existing?.registrationNumber,
  );
  final make = TextEditingController(text: existing?.make);
  final model = TextEditingController(text: existing?.model);
  final year = TextEditingController(
    text: '${existing?.year ?? DateTime.now().year}',
  );
  final type = TextEditingController(text: existing?.type ?? 'SUV');
  final department = TextEditingController(
    text: existing?.assignedDepartment ?? 'Operations',
  );
  final odometer = TextEditingController(
    text: '${existing?.currentOdometer ?? 0}',
  );
  final tank = TextEditingController(text: '${existing?.tankCapacity ?? 70}');
  final consumption = TextEditingController(
    text: '${existing?.expectedFuelConsumption ?? 10}',
  );
  final fuelLimit = TextEditingController(
    text: '${existing?.monthlyFuelLimit ?? 300}',
  );
  final tracker = TextEditingController(text: existing?.gpsTrackerId);
  final insurance = TextEditingController(
    text: existing?.insuranceExpiry ?? '${DateTime.now().year + 1}-12-31',
  );
  final roadworthy = TextEditingController(
    text: existing?.roadworthinessExpiry ?? '${DateTime.now().year + 1}-12-31',
  );
  String driverId = existing?.assignedDriverId ?? '';
  String fuelType = existing?.fuelType ?? 'Diesel';
  VehicleStatus status = existing?.status ?? VehicleStatus.parked;
  bool saving = false;
  String? error;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(existing == null ? 'Add Vehicle' : 'Edit Vehicle'),
        content: SizedBox(
          width: 680,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _row([
                    _field(registration, 'Registration number'),
                    _field(make, 'Make'),
                    _field(model, 'Model'),
                  ]),
                  _row([
                    _field(year, 'Year', number: true),
                    _field(type, 'Vehicle type'),
                    _field(department, 'Department'),
                  ]),
                  _row([
                    _field(odometer, 'Odometer (km)', number: true),
                    _field(tank, 'Tank capacity (L)', number: true),
                    _field(consumption, 'Expected km/L', number: true),
                  ]),
                  _row([
                    _field(fuelLimit, 'Monthly fuel limit (L)', number: true),
                    _field(tracker, 'GPS tracker ID'),
                  ]),
                  _row([
                    _field(insurance, 'Insurance expiry (YYYY-MM-DD)'),
                    _field(roadworthy, 'Roadworthiness expiry (YYYY-MM-DD)'),
                  ]),
                  _row([
                    DropdownButtonFormField<String>(
                      value: fuelType,
                      decoration: const InputDecoration(labelText: 'Fuel type'),
                      items: const ['Diesel', 'Petrol', 'Electric', 'Hybrid']
                          .map(
                            (x) => DropdownMenuItem(value: x, child: Text(x)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => fuelType = v!),
                    ),
                    DropdownButtonFormField<VehicleStatus>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: VehicleStatus.values
                          .map(
                            (x) => DropdownMenuItem(
                              value: x,
                              child: Text(x.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => status = v!),
                    ),
                    DropdownButtonFormField<String>(
                      value: driverId,
                      decoration: const InputDecoration(
                        labelText: 'Assigned driver',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Unassigned'),
                        ),
                        ...data.drivers.map(
                          (d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => driverId = v ?? ''),
                    ),
                  ]),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: saving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() {
                      saving = true;
                      error = null;
                    });
                    try {
                      final now = DateTime.now().toIso8601String();
                      await data.saveVehicle(
                        Vehicle(
                          id:
                              existing?.id ??
                              'v-${DateTime.now().microsecondsSinceEpoch}',
                          registrationNumber: registration.text,
                          make: make.text,
                          model: model.text,
                          year: int.parse(year.text),
                          type: type.text,
                          fuelType: fuelType,
                          tankCapacity: double.parse(tank.text),
                          expectedFuelConsumption: double.parse(
                            consumption.text,
                          ),
                          currentOdometer: double.parse(odometer.text),
                          status: status,
                          assignedDriverId: driverId,
                          assignedDepartment: department.text,
                          insuranceExpiry: insurance.text,
                          roadworthinessExpiry: roadworthy.text,
                          gpsTrackerId: tracker.text,
                          trackerStatus:
                              existing?.trackerStatus ?? TrackerStatus.offline,
                          lastGpsLocation:
                              existing?.lastGpsLocation ??
                              const GpsLocation(
                                lat: 0,
                                lng: 0,
                                address: 'No GPS fix',
                              ),
                          lastGpsUpdateTime: existing?.lastGpsUpdateTime ?? now,
                          monthlyFuelLimit: double.parse(fuelLimit.text),
                          currentMonthFuelUsed:
                              existing?.currentMonthFuelUsed ?? 0,
                        ),
                        updatedBy: 'Fleet Manager',
                      );
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    } catch (e) {
                      setState(() {
                        saving = false;
                        error = e.toString().replaceFirst('Bad state: ', '');
                      });
                    }
                  },
            child: Text(saving ? 'Saving…' : 'Save Vehicle'),
          ),
        ],
      ),
    ),
  );
}

Widget _field(
  TextEditingController controller,
  String label, {
  bool number = false,
}) => TextFormField(
  controller: controller,
  keyboardType: number ? TextInputType.number : TextInputType.text,
  decoration: InputDecoration(labelText: label),
  validator: (v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (number && (double.tryParse(v) == null || double.parse(v) < 0))
      return 'Invalid number';
    return null;
  },
);

Widget _row(List<Widget> children) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Row(
    children: [
      for (var i = 0; i < children.length; i++) ...[
        Expanded(child: children[i]),
        if (i < children.length - 1) const SizedBox(width: 12),
      ],
    ],
  ),
);
