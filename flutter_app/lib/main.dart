import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'root/adaptive_root.dart';
import 'state/fleet_data_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FleetApp());
}

class FleetApp extends StatefulWidget {
  const FleetApp({super.key});

  @override
  State<FleetApp> createState() => _FleetAppState();
}

class _FleetAppState extends State<FleetApp> {
  final FleetDataProvider _data = FleetDataProvider();

  @override
  void initState() {
    super.initState();
    _data.load();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FleetDataProvider>.value(
      value: _data,
      child: MaterialApp(
        title: 'Driver & Fleet Accountability Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: Consumer<FleetDataProvider>(
          builder: (context, data, _) {
            if (!data.isLoaded) {
              return const Scaffold(
                backgroundColor: AppColors.neutral950,
                body: Center(child: CircularProgressIndicator(color: AppColors.amber500)),
              );
            }
            return const AdaptiveRoot();
          },
        ),
      ),
    );
  }
}
