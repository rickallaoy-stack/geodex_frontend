import 'package:flutter_test/flutter_test.dart';

import 'package:geodex/apps/ministere/ministere_app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MinistereApp());
    expect(find.byType(MinistereApp), findsOneWidget);
  });
}
