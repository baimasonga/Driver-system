import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fleet_flutter/config/supabase_config.dart';
import 'package:fleet_flutter/main.dart';
import 'package:fleet_flutter/root/screens/login_screen.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  });

  testWidgets('App boots to the sign-in screen when signed out', (WidgetTester tester) async {
    await tester.pumpWidget(const FleetApp());

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
