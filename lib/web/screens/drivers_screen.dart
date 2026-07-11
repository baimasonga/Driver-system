import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/fleet_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_badge.dart';

class DriversScreen extends StatelessWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();
    final sorted = [...data.drivers]..sort((a, b) => b.riskScore.compareTo(a.riskScore));

    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final d = sorted[i];
        final vehicle = data.vehicleForDriver(d.id);
        final expired = isExpired(d.licenseExpiry);
        final highRisk = d.riskScore >= 50;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.neutral900,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: highRisk ? AppColors.red500.withOpacity(0.4) : AppColors.neutral800),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 24, backgroundImage: NetworkImage(d.photoUrl)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(d.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(width: 8),
                        StatusBadge(label: d.status.label),
                      ],
                    ),
                    Text('${d.staffNumber} · ${d.licenseClass}', style: const TextStyle(color: AppColors.neutral400, fontSize: 11.5)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        _Metric(label: 'Performance', value: '${d.performanceScore}', color: AppColors.green500),
                        _Metric(label: 'Risk Score', value: '${d.riskScore}', color: highRisk ? AppColors.red500 : AppColors.blue500),
                        _Metric(
                          label: 'License Expiry',
                          value: formatDate(d.licenseExpiry),
                          color: expired ? AppColors.red500 : AppColors.neutral100,
                        ),
                        _Metric(label: 'Assigned Vehicle', value: vehicle?.registrationNumber ?? 'None', color: AppColors.neutral100),
                        _Metric(label: 'Phone', value: d.phone, color: AppColors.neutral100),
                      ],
                    ),
                    if (highRisk) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.red500.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'High-risk driver — flagged for closer supervision on fuel & mileage claims.',
                          style: TextStyle(color: AppColors.red500, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Metric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.neutral700, fontSize: 9.5, fontWeight: FontWeight.w700)),
        Text(value, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
