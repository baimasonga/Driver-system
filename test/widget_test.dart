import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fleet_flutter/config/supabase_config.dart';
import 'package:fleet_flutter/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  });

  testWidgets('App boots and shows a loading state before data loads', (WidgetTester tester) async {
    await tester.pumpWidget(const FleetApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
