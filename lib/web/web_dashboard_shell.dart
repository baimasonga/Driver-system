import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import 'screens/overview_screen.dart';
import 'screens/vehicles_screen.dart';
import 'screens/drivers_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/fuel_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/service_forecast_screen.dart';
import 'screens/exceptions_screen.dart';
import 'screens/policies_screen.dart';
import 'screens/incidents_screen.dart';
import 'screens/audit_log_screen.dart';
import 'screens/organization_access_screen.dart';

class NavItem {
  final String label;
  final IconData icon;
  final Widget Function() builder;
  const NavItem(this.label, this.icon, this.builder);
}

class WebDashboardShell extends StatefulWidget {
  const WebDashboardShell({super.key});

  @override
  State<WebDashboardShell> createState() => _WebDashboardShellState();
}

class _WebDashboardShellState extends State<WebDashboardShell> {
  int _index = 0;

  late final List<NavItem> _items = [
    NavItem('Overview', Icons.dashboard_outlined, () => const OverviewScreen()),
    NavItem('Vehicles', Icons.directions_car_outlined, () => const VehiclesScreen()),
    NavItem('Drivers', Icons.badge_outlined, () => const DriversScreen()),
    NavItem('Trip Operations', Icons.route_outlined, () => const TripsScreen()),
    NavItem('Fuel Audits & Approvals', Icons.local_gas_station_outlined, () => const FuelScreen()),
    NavItem('Maintenance Work Orders', Icons.build_outlined, () => const MaintenanceScreen()),
    NavItem('Service Forecast', Icons.monitor_heart_outlined, () => const ServiceForecastScreen()),
    NavItem('Exceptions', Icons.gpp_maybe_outlined, () => const ExceptionsScreen()),
    NavItem('Incidents', Icons.report_gmailerrorred_outlined, () => const IncidentsScreen()),
    NavItem('Policies', Icons.rule_folder_outlined, () => const PoliciesScreen()),
    NavItem('Organization & Access', Icons.admin_panel_settings_outlined, () => const OrganizationAccessScreen()),
    NavItem('Blackbox / Audit', Icons.security_outlined, () => const AuditLogScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    final auth = context.watch<AuthProvider>();

    final sidebar = Container(
      width: wide ? 260 : 76,
      color: AppColors.neutral900,
      child: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(wide ? 24 : 14, 18, 14, 16),
          child: Row(mainAxisAlignment: wide ? MainAxisAlignment.start : MainAxisAlignment.center, children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.amber500, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.shield_outlined, color: AppColors.neutral950, size: 21)),
            if (wide) ...[const SizedBox(width: 11), const Expanded(child: Text('FLEET CONTROL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: .5)))],
          ]),
        ),
        const Divider(height: 1, color: AppColors.neutral800),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                if (wide && _groupTitle(i) != null)
                  Padding(padding: const EdgeInsets.fromLTRB(22, 15, 12, 6), child: Text(_groupTitle(i)!, style: const TextStyle(color: AppColors.neutral700, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: wide ? 10 : 8, vertical: 2),
                  child: Material(
                    color: i == _index ? AppColors.amber500.withOpacity(.13) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _index = i),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: wide ? 12 : 0, vertical: 10),
                        child: Row(mainAxisAlignment: wide ? MainAxisAlignment.start : MainAxisAlignment.center, children: [
                          Icon(_items[i].icon, size: 21, color: i == _index ? AppColors.amber500 : AppColors.neutral400),
                          if (wide) ...[const SizedBox(width: 12), Expanded(child: Text(_items[i].label, style: TextStyle(color: i == _index ? Colors.white : AppColors.neutral300, fontSize: 12, fontWeight: i == _index ? FontWeight.w700 : FontWeight.w500)))],
                        ]),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.neutral800),
        Padding(
          padding: const EdgeInsets.all(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: auth.signOut,
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(mainAxisAlignment: wide ? MainAxisAlignment.start : MainAxisAlignment.center, children: [
              const Icon(Icons.logout, color: AppColors.neutral400, size: 20),
              if (wide) ...[const SizedBox(width: 12), const Text('Sign out', style: TextStyle(color: AppColors.neutral400, fontSize: 12))],
            ])),
          ),
        ),
      ]),
    );

    return Scaffold(
      backgroundColor: AppColors.neutral950,
      body: Row(
        children: [
          sidebar,
          const VerticalDivider(width: 1, color: AppColors.neutral800),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.neutral800)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _items[_index].label,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      if (auth.profile?.fullName != null)
                        Text(auth.profile!.fullName!, style: const TextStyle(color: AppColors.neutral400, fontSize: 12)),
                      if (!wide) ...[
                        const SizedBox(width: 12),
                        IconButton(
                          tooltip: 'Sign out',
                          onPressed: auth.signOut,
                          icon: const Icon(Icons.logout, size: 18),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _items[_index].builder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _groupTitle(int index) {
    if (index == 0) return 'GENERAL';
    if (index == 1) return 'FLEET';
    if (index == 3) return 'OPERATIONS';
    if (index == 7) return 'RISK & COMPLIANCE';
    if (index == 9) return 'ADMINISTRATION';
    return null;
  }
}
