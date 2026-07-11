import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/driver_session.dart';
import '../../state/fleet_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_badge.dart';

class MoreTab extends StatelessWidget {
  final VoidCallback? onSwitchDriver;

  const MoreTab({super.key, this.onSwitchDriver});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();
    final session = context.watch<DriverSession>();
    final driver = data.driverById(session.driverId);
    final vehicle = data.vehicleForDriver(session.driverId);
    final myIncidents = data.incidents.where((i) => i.driverId == session.driverId).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _Tile(
          icon: Icons.checklist_rtl,
          title: 'Pre / Post-Trip Inspection',
          subtitle: 'Submit vehicle condition checklist',
          onTap: vehicle == null ? null : () => _showInspectionSheet(context, data, session.driverId, vehicle.id),
        ),
        const SizedBox(height: 10),
        _Tile(
          icon: Icons.report_gmailerrorred_outlined,
          title: 'Report Incident',
          subtitle: 'Accident, breakdown, violation or complaint',
          onTap: vehicle == null ? null : () => _showIncidentSheet(context, data, session.driverId, vehicle.id),
        ),
        const SizedBox(height: 24),
        const Text('MY REPORTED INCIDENTS', style: TextStyle(color: AppColors.neutral400, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        if (myIncidents.isEmpty) const Text('No incidents reported.', style: TextStyle(color: AppColors.neutral700, fontSize: 12)),
        for (final inc in myIncidents)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.neutral900, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.neutral800)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(inc.category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                      Text(formatDateTime(inc.timestamp), style: const TextStyle(color: AppColors.neutral700, fontSize: 10.5)),
                    ],
                  ),
                ),
                StatusBadge(label: inc.status),
              ],
            ),
          ),
        const SizedBox(height: 24),
        const Divider(color: AppColors.neutral800),
        const SizedBox(height: 12),
        if (driver != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundImage: NetworkImage(driver.photoUrl)),
            title: Text(driver.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            subtitle: Text(driver.email, style: const TextStyle(color: AppColors.neutral400, fontSize: 11.5)),
          ),
        if (onSwitchDriver != null)
          OutlinedButton.icon(
            onPressed: onSwitchDriver,
            icon: const Icon(Icons.swap_horiz, size: 16),
            label: const Text('Switch Driver'),
          ),
      ],
    );
  }

  void _showInspectionSheet(BuildContext context, FleetDataProvider data, String driverId, String vehicleId) {
    final checks = {
      'Fuel level OK': true,
      'Oil level OK': true,
      'Coolant OK': true,
      'Tyres OK': true,
      'Brakes OK': true,
      'Lights OK': true,
      'Body condition OK': true,
      'Spare tyre & tools OK': true,
    };
    String type = 'Pre-Trip';
    final notesController = TextEditingController();

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
                const Text('Vehicle Inspection Checklist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [ButtonSegment(value: 'Pre-Trip', label: Text('Pre-Trip')), ButtonSegment(value: 'Post-Trip', label: Text('Post-Trip'))],
                  selected: {type},
                  onSelectionChanged: (s) => setState(() => type = s.first),
                ),
                const SizedBox(height: 10),
                for (final key in checks.keys)
                  CheckboxListTile(
                    value: checks[key],
                    onChanged: (v) => setState(() => checks[key] = v ?? true),
                    title: Text(key, style: const TextStyle(color: AppColors.neutral100, fontSize: 13)),
                    activeColor: AppColors.amber500,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes (optional)'), maxLines: 2),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      data.submitInspection(
                        vehicleId: vehicleId,
                        driverId: driverId,
                        type: type,
                        fuelLevelOk: checks['Fuel level OK']!,
                        oilLevelOk: checks['Oil level OK']!,
                        coolantOk: checks['Coolant OK']!,
                        tyresOk: checks['Tyres OK']!,
                        brakesOk: checks['Brakes OK']!,
                        lightsOk: checks['Lights OK']!,
                        bodyConditionOk: checks['Body condition OK']!,
                        spareTyreToolsOk: checks['Spare tyre & tools OK']!,
                        notes: notesController.text.isEmpty ? null : notesController.text,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inspection submitted.')));
                    },
                    child: const Text('Submit Inspection'),
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

  void _showIncidentSheet(BuildContext context, FleetDataProvider data, String driverId, String vehicleId) {
    final descController = TextEditingController();
    final locationController = TextEditingController();
    String category = 'Breakdown';

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
                const Text('Report Incident', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  dropdownColor: AppColors.neutral900,
                  items: const ['Accident', 'Breakdown', 'Violation', 'Theft', 'Passenger Complaint']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
                const SizedBox(height: 12),
                TextField(controller: descController, maxLines: 3, decoration: const InputDecoration(labelText: 'What happened?')),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      data.reportIncident(
                        category: category,
                        vehicleId: vehicleId,
                        driverId: driverId,
                        description: descController.text.isEmpty ? 'No further details provided.' : descController.text,
                        location: locationController.text.isEmpty ? 'Unspecified' : locationController.text,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Incident reported. Security notified.')),
                      );
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

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _Tile({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.neutral900, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.neutral800)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.amber500.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.amber500, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                  Text(subtitle, style: const TextStyle(color: AppColors.neutral400, fontSize: 11.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }
}
