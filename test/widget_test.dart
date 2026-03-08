// Basic widget test for the Catrin & Abi BSL app.

import 'package:flutter_test/flutter_test.dart';

import 'package:catrin_abi_bsl/app.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CatrinAbiApp());

    // Verify the app builds successfully
    expect(find.byType(CatrinAbiApp), findsOneWidget);
  });
}
