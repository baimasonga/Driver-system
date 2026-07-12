import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/fleet_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class ServiceForecastScreen extends StatefulWidget {
  const ServiceForecastScreen({super.key});
  @override State<ServiceForecastScreen> createState() => _ServiceForecastScreenState();
}

class _ServiceForecastScreenState extends State<ServiceForecastScreen> {
  double scenarioKm = 0;
  @override Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const Expanded(child: Text('Wear projections use odometer, completed GPS trips, department stress and verified service history.', style: TextStyle(color: AppColors.neutral400))),
        OutlinedButton.icon(onPressed: () => setState(() => scenarioKm = scenarioKm == 0 ? 1500 : 0), icon: const Icon(Icons.science_outlined), label: Text(scenarioKm == 0 ? 'Simulate +1,500 KM' : 'Clear Simulation')),
      ]),
      if (scenarioKm > 0) const Padding(padding: EdgeInsets.only(top: 8), child: Text('SCENARIO ONLY — real odometers are unchanged.', style: TextStyle(color: AppColors.amber500, fontWeight: FontWeight.w700))),
      const SizedBox(height: 16),
      Expanded(child: data.vehicles.isEmpty ? const Center(child: Text('Add vehicles to generate service forecasts.', style: TextStyle(color: AppColors.neutral400))) : ListView.separated(
        itemCount: data.vehicles.length, separatorBuilder: (_, __) => const SizedBox(height: 14), itemBuilder: (context, i) {
          final forecast = ServiceForecastEngine.calculate(data.vehicles[i], data.trips, data.maintenanceRequests, scenarioKm: scenarioKm);
          return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.neutral900, borderRadius: BorderRadius.circular(18), border: Border.all(color: forecast.hasOverdueComponent ? AppColors.red500 : AppColors.neutral800)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text('${forecast.vehicle.registrationNumber} · ${forecast.vehicle.make} ${forecast.vehicle.model}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))), Text('${forecast.averageDailyKm.toStringAsFixed(1)} km/day', style: const TextStyle(color: AppColors.neutral400))]),
            const SizedBox(height: 14),
            for (final c in forecast.components) Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(children: [
              Row(children: [Expanded(child: Text(c.name, style: const TextStyle(color: AppColors.neutral100, fontWeight: FontWeight.w700))), Text(c.overdue ? 'OVERDUE ${formatKm(-c.remainingKm)}' : '${formatKm(c.remainingKm)} · ${c.projectedDate.toIso8601String().substring(0, 10)}', style: TextStyle(color: c.overdue ? AppColors.red500 : AppColors.neutral400, fontSize: 11))]),
              const SizedBox(height: 5), LinearProgressIndicator(value: c.wearRatio.clamp(0, 1).toDouble(), color: c.overdue ? AppColors.red500 : c.wearRatio > .8 ? AppColors.amber500 : AppColors.green500, backgroundColor: AppColors.neutral800),
            ])),
            Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: forecast.vehicle.assignedDriverId.isEmpty ? null : () async {
              await data.submitMaintenanceRequest(vehicleId: forecast.vehicle.id, driverId: forecast.vehicle.assignedDriverId, category: 'Routine', description: 'Preventive service dispatch generated from wear forecast.', severity: forecast.hasOverdueComponent ? 'High' : 'Medium', odometer: forecast.vehicle.currentOdometer);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preventive work order created for approval.')));
            }, icon: const Icon(Icons.build_circle_outlined), label: const Text('Create Preventive Work Order'))),
          ]));
        }))
    ]);
  }
}
