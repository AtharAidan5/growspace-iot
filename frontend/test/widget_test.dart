import 'package:flutter_test/flutter_test.dart';

import 'package:ioe_dashboard/main.dart';

void main() {
  testWidgets('app builds and shows the dashboard shell', (tester) async {
    await tester.pumpWidget(const IoeDashboardApp());
    expect(find.text('GrowSpace 🌿'), findsOneWidget);
  });
}
