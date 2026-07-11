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
import 'screens/exceptions_screen.dart';
import 'screens/policies_screen.dart';
import 'screens/incidents_screen.dart';
import 'screens/audit_log_screen.dart';

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
    NavItem('Trips', Icons.route_outlined, () => const TripsScreen()),
    NavItem('Fuel & Theft', Icons.local_gas_station_outlined, () => const FuelScreen()),
    NavItem('Maintenance', Icons.build_outlined, () => const MaintenanceScreen()),
    NavItem('Exceptions', Icons.gpp_maybe_outlined, () => const ExceptionsScreen()),
    NavItem('Incidents', Icons.report_gmailerrorred_outlined, () => const IncidentsScreen()),
    NavItem('Policies', Icons.rule_folder_outlined, () => const PoliciesScreen()),
    NavItem('Blackbox / Audit', Icons.security_outlined, () => const AuditLogScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    final auth = context.watch<AuthProvider>();

    final rail = NavigationRail(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      backgroundColor: AppColors.neutral900,
      labelType: wide ? NavigationRailLabelType.none : NavigationRailLabelType.selected,
      extended: wide,
      minExtendedWidth: 210,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: wide ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AppColors.amber500, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.shield_outlined, color: AppColors.neutral950, size: 20),
            ),
            if (wide) ...[
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'FLEET CONTROL',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: IconButton(
              tooltip: 'Sign out',
              onPressed: auth.signOut,
              icon: const Icon(Icons.logout, color: AppColors.neutral400),
            ),
          ),
        ),
      ),
      destinations: _items
          .map((e) => NavigationRailDestination(
                icon: Icon(e.icon),
                selectedIcon: Icon(e.icon, color: AppColors.amber500),
                label: Text(e.label),
              ))
          .toList(),
    );

    return Scaffold(
      backgroundColor: AppColors.neutral950,
      body: Row(
        children: [
          rail,
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
}
