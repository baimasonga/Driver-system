import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/fleet_data_provider.dart';
import '../../theme/app_theme.dart';

class DriverSelectScreen extends StatelessWidget {
  final VoidCallback? onSwitchToWebPreview;
  final ValueChanged<String> onDriverSelected;

  const DriverSelectScreen({super.key, this.onSwitchToWebPreview, required this.onDriverSelected});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();

    return Scaffold(
      backgroundColor: AppColors.neutral950,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: AppColors.amber500, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.shield_outlined, color: AppColors.neutral950, size: 28),
                  ),
                  const Spacer(),
                  if (onSwitchToWebPreview != null)
                    IconButton(
                      tooltip: 'Preview web console',
                      onPressed: onSwitchToWebPreview,
                      icon: const Icon(Icons.laptop_mac_outlined, color: AppColors.neutral400),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Driver Sign In', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text(
                'Select your staff profile to access trips, fuel, maintenance and incident reporting.',
                style: TextStyle(color: AppColors.neutral400, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: data.drivers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final d = data.drivers[i];
                    final vehicle = data.vehicleForDriver(d.id);
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => onDriverSelected(d.id),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.neutral900,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.neutral800),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 24, backgroundImage: NetworkImage(d.photoUrl)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                  Text('${d.staffNumber} · ${vehicle?.registrationNumber ?? "Unassigned"}',
                                      style: const TextStyle(color: AppColors.neutral400, fontSize: 11.5)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.neutral400),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
