import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/fleet_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: AppColors.amber500.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.amber500.withOpacity(0.25))),
          child: const Row(
            children: [
              Icon(Icons.lock_outline, color: AppColors.amber500, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Immutable append-only trail of every action taken across the web console and driver app.',
                  style: TextStyle(color: AppColors.amber500, fontSize: 11.5),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: data.auditLogs.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.neutral800, height: 24),
            itemBuilder: (context, i) {
              final l = data.auditLogs[i];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.amber500, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(l.action, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5))),
                            Text(formatDateTime(l.timestamp), style: const TextStyle(color: AppColors.neutral700, fontSize: 10.5)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(l.details, style: const TextStyle(color: AppColors.neutral300, fontSize: 12)),
                        const SizedBox(height: 3),
                        Text('${l.userId} · ${l.userRole} · ${l.entityType} #${l.entityId}', style: const TextStyle(color: AppColors.neutral700, fontSize: 10.5)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
