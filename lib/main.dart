import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'root/adaptive_root.dart';
import 'state/auth_provider.dart';
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
  final AuthProvider _auth = AuthProvider();
  final FleetDataProvider _data = FleetDataProvider();

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
    // Handle an already-persisted session from a previous app launch.
    if (_auth.session != null) _data.load();
  }

  void _onAuthChanged() {
    if (_auth.session != null) {
      if (!_data.isLoaded) _data.load();
    } else {
      _data.reset();
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _auth.dispose();
    _data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider<FleetDataProvider>.value(value: _data),
      ],
      child: MaterialApp(
        title: 'Driver & Fleet Accountability Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const AdaptiveRoot(),
      ),
    );
  }
}
