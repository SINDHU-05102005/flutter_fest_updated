import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/main.dart';

void main() {
  testWidgets('Dashboard renders and navigation works', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CollegeFestDashboard()),
    );

    expect(find.text('KLE Haveri BCA Fest'), findsOneWidget);

    await tester.tap(find.text('Events'));
    await tester.pump();

    expect(find.text('Featured Events'), findsOneWidget);
  });
}
