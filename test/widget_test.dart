import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleet_flutter/main.dart';

void main() {
  testWidgets('App boots and shows a loading state before data loads', (WidgetTester tester) async {
    await tester.pumpWidget(const FleetApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
