import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../mobile/driver_app_shell.dart';
import '../mobile/screens/driver_select_screen.dart';
import '../web/web_dashboard_shell.dart';

/// Single Flutter codebase, two front-ends: a Fleet Manager web console and
/// an Android driver app. The platform this binary was built for decides
/// the default landing experience; either side can still preview the other
/// for training / demo purposes, mirroring the original combined demo.
///
/// Both sides are swapped in-place (no Navigator push) so that switching
/// back and forth always works regardless of how deep the user has
/// navigated within either experience.
class AdaptiveRoot extends StatefulWidget {
  const AdaptiveRoot({super.key});

  @override
  State<AdaptiveRoot> createState() => _AdaptiveRootState();
}

class _AdaptiveRootState extends State<AdaptiveRoot> {
  late bool _showWeb = kIsWeb;
  String? _selectedDriverId;

  @override
  Widget build(BuildContext context) {
    if (_showWeb) {
      return WebDashboardShell(onSwitchToMobilePreview: () => setState(() => _showWeb = false));
    }

    final onSwitchToWebPreview = kIsWeb ? null : () => setState(() => _showWeb = true);

    if (_selectedDriverId == null) {
      return DriverSelectScreen(
        onSwitchToWebPreview: onSwitchToWebPreview,
        onDriverSelected: (id) => setState(() => _selectedDriverId = id),
      );
    }

    return DriverAppShell(
      driverId: _selectedDriverId!,
      onSwitchToWebPreview: onSwitchToWebPreview,
      onSwitchDriver: () => setState(() => _selectedDriverId = null),
    );
  }
}
