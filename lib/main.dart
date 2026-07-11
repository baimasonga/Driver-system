import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'root/adaptive_root.dart';
import 'state/fleet_data_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
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
  void dispose() {
    _data.dispose();
    super.dispose();
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
            if (data.loadError != null) {
              return Scaffold(
                backgroundColor: AppColors.neutral950,
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, color: AppColors.red500, size: 40),
                        const SizedBox(height: 16),
                        const Text(
                          "Couldn't reach the fleet backend",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data.loadError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.neutral400, fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(onPressed: data.load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const AdaptiveRoot();
          },
        ),
      ),
    );
  }
}
