import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/fleet_data_provider.dart';
import '../../state/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_badge.dart';

class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();
    if (data.incidents.isEmpty) {
      return const Center(
        child: Text(
          'No incidents reported.',
          style: TextStyle(color: AppColors.neutral400),
        ),
      );
    }
    return ListView.separated(
      itemCount: data.incidents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final inc = data.incidents[i];
        final vehicle = data.vehicleById(inc.vehicleId);
        final driver = data.driverById(inc.driverId);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.neutral900,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.neutral800),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      inc.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  StatusBadge(label: inc.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                inc.description,
                style: const TextStyle(
                  color: AppColors.neutral300,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${vehicle?.registrationNumber ?? inc.vehicleId} · ${driver?.name ?? inc.driverId} · ${inc.location}',
                style: const TextStyle(
                  color: AppColors.neutral400,
                  fontSize: 11,
                ),
              ),
              Text(
                formatDateTime(inc.timestamp),
                style: const TextStyle(
                  color: AppColors.neutral700,
                  fontSize: 10.5,
                ),
              ),
              if (inc.status != 'Resolved') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (inc.status == 'Pending')
                      OutlinedButton(
                        onPressed: () => _update(
                          context,
                          data,
                          inc.id,
                          'Under Investigation',
                        ),
                        child: const Text('Investigate'),
                      ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () =>
                          _update(context, data, inc.id, 'Resolved'),
                      child: const Text('Mark Resolved'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _update(
    BuildContext context,
    FleetDataProvider data,
    String id,
    String status,
  ) async {
    try {
      final name =
          context.read<AuthProvider>().profile?.fullName ?? 'Fleet Manager';
      await data.updateIncidentStatus(id, status, updatedBy: name);
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
    }
  }
}
