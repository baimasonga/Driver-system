import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_provider.dart';
import '../state/driver_session.dart';
import '../theme/app_theme.dart';
import 'screens/home_tab.dart';
import 'screens/trips_tab.dart';
import 'screens/fuel_tab.dart';
import 'screens/maintenance_tab.dart';
import 'screens/more_tab.dart';

class DriverAppShell extends StatefulWidget {
  final String driverId;

  const DriverAppShell({super.key, required this.driverId});

  @override
  State<DriverAppShell> createState() => _DriverAppShellState();
}

class _DriverAppShellState extends State<DriverAppShell> {
  int _index = 0;
  late final DriverSession _session = DriverSession(widget.driverId);

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final tabs = [
      const HomeTab(),
      const TripsTab(),
      const FuelTab(),
      const MaintenanceTab(),
      MoreTab(onSignOut: auth.signOut),
    ];

    return ChangeNotifierProvider.value(
      value: _session,
      child: Scaffold(
        backgroundColor: AppColors.neutral950,
        appBar: AppBar(
          title: const Text('Driver App', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          actions: [
            Consumer<DriverSession>(
              builder: (context, session, _) => IconButton(
                tooltip: session.isOnline ? 'Online — tap to go offline' : 'Offline — tap to sync',
                onPressed: () => session.setOnline(!session.isOnline),
                icon: Icon(
                  session.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: session.isOnline ? AppColors.green500 : AppColors.red500,
                ),
              ),
            ),
          ],
        ),
        body: IndexedStack(index: _index, children: tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: AppColors.neutral900,
          indicatorColor: AppColors.amber500.withOpacity(0.18),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.amber500), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route, color: AppColors.amber500), label: 'Trips'),
            NavigationDestination(icon: Icon(Icons.local_gas_station_outlined), selectedIcon: Icon(Icons.local_gas_station, color: AppColors.amber500), label: 'Fuel'),
            NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build, color: AppColors.amber500), label: 'Repairs'),
            NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz, color: AppColors.amber500), label: 'More'),
          ],
        ),
      ),
    );
  }
}
