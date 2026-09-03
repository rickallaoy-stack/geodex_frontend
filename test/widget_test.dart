import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geodex/apps/auth/login_screen.dart';
import 'package:geodex/apps/borne/borne_app.dart';

void main() {
  testWidgets('LoginScreen loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: LoginScreen(),
    ));
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Borne kiosk renders on desktop and mobile', (WidgetTester tester) async {
    Future<void> pumpAt(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(const MaterialApp(home: BorneApp()));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('GEODEX'), findsWidgets);
      expect(find.text('PRESENTEZ VOTRE CARTE'), findsOneWidget);
      expect(find.textContaining('MODE DEMO'), findsOneWidget);
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpAt(const Size(1280, 800));
    await pumpAt(const Size(400, 780));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 4));
  });
}
