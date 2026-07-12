import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/driver_session.dart';
import '../../state/fleet_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_badge.dart';

class FuelTab extends StatelessWidget {
  const FuelTab({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();
    final session = context.watch<DriverSession>();
    final vehicle = data.vehicleForDriver(session.driverId);
    final myRequests = data.fuelRequests.where((f) => f.driverId == session.driverId).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: vehicle == null ? null : () => _showFuelSheet(context, data, session.driverId, vehicle.id, vehicle.currentOdometer),
        icon: const Icon(Icons.local_gas_station),
        label: const Text('Request Fuel'),
      ),
      body: myRequests.isEmpty
          ? const Center(child: Text('No fuel requests yet.', style: TextStyle(color: AppColors.neutral400)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: myRequests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final f = myRequests[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.neutral900,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: f.varianceFlagged == true ? AppColors.red500.withOpacity(0.5) : AppColors.neutral800),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(f.stationName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5))),
                          StatusBadge(label: f.varianceFlagged == true ? 'Flagged Variance' : f.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${formatLiters(f.requestedLiters)} · ${formatCurrency(f.estimatedCost)}', style: const TextStyle(color: AppColors.neutral300, fontSize: 12)),
                      const SizedBox(height: 3),
                      Text(formatDateTime(f.timestamp), style: const TextStyle(color: AppColors.neutral700, fontSize: 10.5)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showFuelSheet(BuildContext context, FleetDataProvider data, String driverId, String vehicleId, double odometer) {
    final odoController = TextEditingController(text: odometer.toStringAsFixed(0));
    final litersController = TextEditingController(text: '40');
    final costController = TextEditingController(text: '80');
    final stationController = TextEditingController(text: 'TotalEnergies Wilberforce');
    final receiptController = TextEditingController();
    final cardReferenceController = TextEditingController();
    final unitPriceController = TextEditingController(text: '2');
    String paymentMethod = 'Cash';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.neutral900,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Request Fuel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('Capture the receipt and payment references used for audit reconciliation.', style: TextStyle(color: AppColors.neutral400, fontSize: 11.5)),
              const SizedBox(height: 16),
              TextField(controller: stationController, decoration: const InputDecoration(labelText: 'Station name')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                items: const [DropdownMenuItem(value: 'Cash', child: Text('Cash')), DropdownMenuItem(value: 'Fuel Card', child: Text('Fuel Card'))],
                onChanged: (v) => setSheetState(() => paymentMethod = v!),
                decoration: const InputDecoration(labelText: 'Payment method'),
              ),
              const SizedBox(height: 12),
              TextField(controller: receiptController, decoration: const InputDecoration(labelText: 'Receipt number')),
              if (paymentMethod == 'Fuel Card') ...[
                const SizedBox(height: 12),
                TextField(controller: cardReferenceController, decoration: const InputDecoration(labelText: 'Card transaction reference')),
              ],
              const SizedBox(height: 12),
              TextField(controller: odoController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current odometer (KM)')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: litersController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Liters requested'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: costController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Estimated cost (\$)'))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: unitPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit price per litre')),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final enteredOdometer = double.tryParse(odoController.text.trim());
                    final liters = double.tryParse(litersController.text.trim());
                    final cost = double.tryParse(costController.text.trim());
                    final station = stationController.text.trim();
                    final unitPrice = double.tryParse(unitPriceController.text.trim());
                    if (enteredOdometer == null || enteredOdometer < odometer || liters == null || liters <= 0 || cost == null || cost <= 0 || unitPrice == null || unitPrice <= 0 || station.isEmpty || receiptController.text.trim().isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Enter a valid station, odometer, litres, and cost.')),
                      );
                      return;
                    }
                    try {
                      await data.submitFuelRequest(
                        vehicleId: vehicleId,
                        driverId: driverId,
                        odometer: enteredOdometer,
                        requestedLiters: liters,
                        estimatedCost: cost,
                        stationName: station,
                        paymentMethod: paymentMethod,
                        receiptNumber: receiptController.text.trim(),
                        cardTransactionReference: cardReferenceController.text.trim(),
                        unitPrice: unitPrice,
                      );
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Fuel claim submitted for manager approval.')),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Could not submit fuel claim: $e')),
                      );
                    }
                  },
                  child: const Text('Submit Claim'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      )),
    );
  }
}
