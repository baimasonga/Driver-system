import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/driver_session.dart';
import '../../state/auth_provider.dart';
import '../../state/fleet_data_provider.dart';
import '../../services/evidence_upload_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_badge.dart';

class MaintenanceTab extends StatelessWidget {
  const MaintenanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();
    final session = context.watch<DriverSession>();
    final vehicle = data.vehicleForDriver(session.driverId);
    final myRequests = data.maintenanceRequests.where((m) => m.driverId == session.driverId).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: vehicle == null ? null : () => _showSheet(context, data, session.driverId, vehicle.id, vehicle.currentOdometer),
        icon: const Icon(Icons.report_problem_outlined),
        label: const Text('Report Defect'),
      ),
      body: myRequests.isEmpty
          ? const Center(child: Text('No maintenance requests filed.', style: TextStyle(color: AppColors.neutral400)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: myRequests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final m = myRequests[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.neutral900, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.neutral800)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(m.category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5))),
                          StatusBadge(label: m.status.label),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(m.description, style: const TextStyle(color: AppColors.neutral300, fontSize: 12)),
                      const SizedBox(height: 3),
                      Text(formatDateTime(m.timestamp), style: const TextStyle(color: AppColors.neutral700, fontSize: 10.5)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showSheet(BuildContext context, FleetDataProvider data, String driverId, String vehicleId, double odometer) {
    final descController = TextEditingController();
    String category = 'Corrective';
    String severity = 'Medium';
    String? diagnosticEvidence;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.neutral900,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Report Vehicle Defect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  dropdownColor: AppColors.neutral900,
                  items: const ['Routine', 'Corrective', 'Emergency'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: severity,
                  decoration: const InputDecoration(labelText: 'Severity'),
                  dropdownColor: AppColors.neutral900,
                  items: const ['Low', 'Medium', 'High'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => severity = v ?? severity),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Describe the fault'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final org = context.read<AuthProvider>().profile!.organizationId;
                      final path = await EvidenceUploadService.pickAndUpload(organizationId: org, category: 'maintenance-diagnostics');
                      if (path != null) setState(() => diagnosticEvidence = path);
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  },
                  icon: Icon(diagnosticEvidence == null ? Icons.add_a_photo_outlined : Icons.check_circle),
                  label: Text(diagnosticEvidence == null ? 'Attach Diagnostic Photo' : 'Diagnostic Evidence Attached'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      try {
                        await data.submitMaintenanceRequest(
                          vehicleId: vehicleId,
                          driverId: driverId,
                          category: category,
                          description: descController.text.isEmpty ? 'Unspecified fault reported by driver.' : descController.text,
                          severity: severity,
                          odometer: odometer,
                          beforePhotoUrl: diagnosticEvidence,
                        );
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Defect logged. Fleet manager notified.')),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Could not log defect: $e')),
                        );
                      }
                    },
                    child: const Text('Submit Report'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
