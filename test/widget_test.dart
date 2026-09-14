import 'package:flutter_test/flutter_test.dart';

import 'package:desktop/app.dart';

void main() {
  testWidgets('Dhandas app loads home workspace', (WidgetTester tester) async {
    await tester.pumpWidget(const DhandasApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Dhandas'), findsWidgets);
    expect(find.text('Settings & Preferences'), findsNothing);
  });
}
