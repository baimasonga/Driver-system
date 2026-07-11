import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../mobile/driver_app_shell.dart';
import '../state/auth_provider.dart';
import '../state/fleet_data_provider.dart';
import '../theme/app_theme.dart';
import '../web/web_dashboard_shell.dart';
import 'screens/login_screen.dart';

/// Single Flutter codebase, two front-ends: a Fleet Manager web console and
/// an Android driver app, both gated behind the same Supabase Auth sign-in.
/// Which one a signed-in user lands on is decided by their `profiles.role`,
/// not by platform -- a manager always gets the console, a driver always
/// gets the driver app, regardless of whether they're on web or Android.
class AdaptiveRoot extends StatelessWidget {
  const AdaptiveRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.session == null) {
      return const LoginScreen();
    }

    if (auth.isLoadingProfile) {
      return const _FullScreenSpinner();
    }

    if (auth.profile == null) {
      return Scaffold(
        backgroundColor: AppColors.neutral950,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_circle_outlined, color: AppColors.red500, size: 42),
                  const SizedBox(height: 16),
                  const Text(
                    'Your account profile could not be loaded',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    auth.profileError ?? 'No profile record is linked to this account.',
                    style: const TextStyle(color: AppColors.neutral400, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(onPressed: auth.retryProfile, child: const Text('Retry')),
                      OutlinedButton(onPressed: auth.signOut, child: const Text('Sign Out')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final data = context.watch<FleetDataProvider>();

    if (!data.isLoaded) {
      return const _FullScreenSpinner();
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

    if (auth.profile!.isManager) {
      return const WebDashboardShell();
    }

    final driverId = auth.profile!.driverId;
    if (driverId == null) {
      return Scaffold(
        backgroundColor: AppColors.neutral950,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This account has no linked driver profile.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: auth.signOut, child: const Text('Sign Out')),
              ],
            ),
          ),
        ),
      );
    }

    return DriverAppShell(driverId: driverId);
  }
}

class _FullScreenSpinner extends StatelessWidget {
  const _FullScreenSpinner();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.neutral950,
      body: Center(child: CircularProgressIndicator(color: AppColors.amber500)),
    );
  }
}
