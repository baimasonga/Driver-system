import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/fleet_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/severity_badge.dart';
import '../../widgets/status_badge.dart';

class ExceptionsScreen extends StatefulWidget {
  const ExceptionsScreen({super.key});

  @override
  State<ExceptionsScreen> createState() => _ExceptionsScreenState();
}

class _ExceptionsScreenState extends State<ExceptionsScreen> {
  String _filter = 'Open';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();
    final filters = ['Open', 'In Investigation', 'Resolved', 'All'];
    final list = _filter == 'All' ? data.exceptions : data.exceptions.where((e) => e.status == _filter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final f = filters[i];
              final selected = f == _filter;
              return ChoiceChip(
                label: Text(f),
                selected: selected,
                onSelected: (_) => setState(() => _filter = f),
                selectedColor: AppColors.amber500,
                labelStyle: TextStyle(color: selected ? AppColors.neutral950 : AppColors.neutral300, fontWeight: FontWeight.w700, fontSize: 11.5),
                backgroundColor: AppColors.neutral900,
                side: BorderSide(color: selected ? AppColors.amber500 : AppColors.neutral800),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('No exceptions in this state.', style: TextStyle(color: AppColors.neutral400)))
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final e = list[i];
                    final vehicle = data.vehicleById(e.vehicleId);
                    final driver = e.driverId != null ? data.driverById(e.driverId!) : null;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.neutral900,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.severityColor(e.severity.label).withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SeverityBadge(severity: e.severity.label),
                              const SizedBox(width: 8),
                              StatusBadge(label: e.status),
                              const Spacer(),
                              Text(e.type, style: const TextStyle(color: AppColors.neutral400, fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(e.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
                          const SizedBox(height: 6),
                          Text(e.description, style: const TextStyle(color: AppColors.neutral300, fontSize: 12, height: 1.4)),
                          const SizedBox(height: 10),
                          Text(
                            '${vehicle?.registrationNumber ?? e.vehicleId}${driver != null ? " · ${driver.name}" : ""} · ${formatDateTime(e.timestamp)}',
                            style: const TextStyle(color: AppColors.neutral700, fontSize: 10.5),
                          ),
                          if (e.status == 'Resolved' && e.resolutionNotes != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.green500.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: Text('Resolved by ${e.resolvedBy}: ${e.resolutionNotes}', style: const TextStyle(color: AppColors.green500, fontSize: 11.5)),
                            ),
                          ],
                          if (e.status != 'Resolved') ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (e.status == 'Open')
                                  OutlinedButton(
                                    onPressed: () => data.setExceptionStatus(e.id, 'In Investigation'),
                                    child: const Text('Investigate'),
                                  ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () => _resolve(context, data, e.id),
                                  child: const Text('Seal & Resolve'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _resolve(BuildContext context, FleetDataProvider data, String id) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.neutral900,
        title: const Text('Seal Exception File', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Resolution notes / findings'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              data.resolveException(id, resolvedBy: 'M. Bangura (Fleet Mgr)', resolutionNotes: controller.text);
              Navigator.pop(context);
            },
            child: const Text('Seal File'),
          ),
        ],
      ),
    );
  }
}
