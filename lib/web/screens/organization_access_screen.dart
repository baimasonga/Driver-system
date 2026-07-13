import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../state/auth_provider.dart';
import '../../theme/app_theme.dart';

class OrganizationAccessScreen extends StatelessWidget {
  const OrganizationAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile!;
    return FutureBuilder<Map<String, dynamic>>(
      future: Supabase.instance.client.from('organizations').select().eq('id', profile.organizationId).single(),
      builder: (context, snapshot) {
        final org = snapshot.data;
        return ListView(children: [
          _panel('Organization', Icons.apartment_outlined, [
            _row('Name', org?['name'] ?? 'Loading…'),
            _row('Tenant ID', profile.organizationId),
            _row('Status', org?['status'] ?? 'Loading…'),
          ]),
          const SizedBox(height: 14),
          _panel('Your Access', Icons.admin_panel_settings_outlined, [
            _row('Signed-in user', profile.email ?? profile.id),
            _row('Role', _roleName(profile.role)),
            _row('Data boundary', 'This organization only'),
          ]),
          const SizedBox(height: 14),
          _panel('Commercial Security', Icons.verified_user_outlined, const [
            _Status('Tenant-isolated database records', true),
            _Status('Role-based database policies', true),
            _Status('Private evidence storage', true),
            _Status('10 MB evidence size limit', true),
            _Status('Public/anonymous fleet access blocked', true),
          ]),
          const SizedBox(height: 14),
          _panel('Operational Roles', Icons.groups_2_outlined, const [
            _Role('Administrator', 'Organization setup and full control'),
            _Role('Fleet Manager', 'Fleet records, operations and reporting'),
            _Role('Approver', 'Trip, fuel and maintenance decisions'),
            _Role('Dispatcher', 'Trip planning and vehicle assignment'),
            _Role('Gate Officer', 'Vehicle departure and return capture'),
            _Role('Storekeeper', 'Parts inventory and serialized issues'),
            _Role('Garage', 'Diagnostics and repair completion evidence'),
            _Role('Driver', 'Mobile trips, fuel, defects and incidents'),
          ]),
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.amber500.withOpacity(.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.amber500.withOpacity(.35))),
            child: const Text('User invitations and role assignment require an administrator workflow. Until that screen is completed, accounts are created in Supabase Authentication and assigned securely in profiles.', style: TextStyle(color: AppColors.amber500, height: 1.4))),
        ]);
      },
    );
  }

  Widget _panel(String title, IconData icon, List<Widget> children) => Container(
    padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.neutral900, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.neutral800)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: AppColors.amber500, size: 20), const SizedBox(width: 9), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))]),
      const SizedBox(height: 14), ...children,
    ]));

  static Widget _row(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(children: [SizedBox(width: 180, child: Text(label, style: const TextStyle(color: AppColors.neutral400))), Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))]));
  static String _roleName(String role) => role.split('_').map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

class _Status extends StatelessWidget {
  final String label; final bool enabled; const _Status(this.label, this.enabled);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(children: [Icon(enabled ? Icons.check_circle : Icons.cancel, color: enabled ? AppColors.green500 : AppColors.red500, size: 17), const SizedBox(width: 8), Text(label, style: const TextStyle(color: AppColors.neutral100))]));
}
class _Role extends StatelessWidget {
  final String name, description; const _Role(this.name, this.description);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 150, child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))), Expanded(child: Text(description, style: const TextStyle(color: AppColors.neutral400)))]));
}
