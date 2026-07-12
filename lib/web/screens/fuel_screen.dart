import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/fleet_data_provider.dart';
import '../../state/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';

class FuelScreen extends StatelessWidget {
  const FuelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();
    final pending = data.fuelRequests
        .where((f) => f.status == 'Pending')
        .toList();
    final flagged = data.fuelRequests
        .where((f) => f.varianceFlagged == true)
        .length;
    final totalLiters = data.fuelRequests
        .where((f) => f.status == 'Completed')
        .fold<double>(
          0,
          (sum, f) => sum + (f.actualLiters ?? f.requestedLiters),
        );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Pending Approval',
                  value: '${pending.length}',
                  icon: Icons.hourglass_bottom,
                  accent: AppColors.amber500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Variance Flags',
                  value: '$flagged',
                  icon: Icons.warning_amber_rounded,
                  accent: AppColors.red500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Total Fuelled',
                  value: formatLiters(totalLiters),
                  icon: Icons.local_gas_station,
                  accent: AppColors.blue500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (pending.isNotEmpty) ...[
            const SectionHeader(
              title: 'Awaiting Approval',
              icon: Icons.hourglass_bottom,
            ),
            for (final f in pending) _FuelCard(id: f.id, pending: true),
            const SizedBox(height: 24),
          ],
          const SectionHeader(
            title: 'Fuel Transaction History',
            icon: Icons.receipt_long_outlined,
          ),
          for (final f in data.fuelRequests.where((f) => f.status != 'Pending'))
            _FuelCard(id: f.id, pending: false),
        ],
      ),
    );
  }
}

class _FuelCard extends StatelessWidget {
  final String id;
  final bool pending;
  const _FuelCard({required this.id, required this.pending});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();
    final f = data.fuelRequests.firstWhere((e) => e.id == id);
    final vehicle = data.vehicleById(f.vehicleId);
    final driver = data.driverById(f.driverId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neutral900,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: f.varianceFlagged == true
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
                  '${vehicle?.registrationNumber ?? f.vehicleId} · ${driver?.name ?? f.driverId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              StatusBadge(
                label: f.varianceFlagged == true
                    ? 'Flagged Variance'
                    : f.status,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            f.stationName,
            style: const TextStyle(color: AppColors.neutral400, fontSize: 11.5),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 20,
            runSpacing: 6,
            children: [
              _kv('Requested', formatLiters(f.requestedLiters)),
              _kv('Est. Cost', formatCurrency(f.estimatedCost)),
              _kv('Odometer', formatKm(f.odometer)),
              _kv('Voucher', f.voucherCode ?? '-'),
              _kv('Payment', f.paymentMethod),
              _kv('Receipt', f.receiptNumber ?? '-'),
              if (f.cardTransactionReference != null) _kv('Card Ref', f.cardTransactionReference!),
              if (f.calculatedKmPerLiter != null) _kv('Actual km/L', f.calculatedKmPerLiter!.toStringAsFixed(1)),
              _kv('Submitted', formatDateTime(f.timestamp)),
            ],
          ),
          if (f.varianceFlagged == true && f.varianceReason != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.red500.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                f.varianceReason!,
                style: const TextStyle(color: AppColors.red500, fontSize: 11.5),
              ),
            ),
          ],
          if (pending) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    try {
                      final name =
                          context.read<AuthProvider>().profile?.fullName ??
                          'Fleet Manager';
                      await data.rejectFuelRequest(
                        f.id,
                        approver: name,
                        reason: 'Rejected after manual review.',
                      );
                    } catch (e) {
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Bad state: ', ''),
                            ),
                          ),
                        );
                    }
                  },
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final name =
                          context.read<AuthProvider>().profile?.fullName ??
                          'Fleet Manager';
                      await data.approveFuelRequest(f.id, approver: name);
                    } catch (e) {
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Bad state: ', ''),
                            ),
                          ),
                        );
                    }
                  },
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ],
      ),
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
}
