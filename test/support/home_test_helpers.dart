import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens Settings from the home navigation, unless it is already open, and taps
/// the row labelled [label]. The caller pumps afterwards, since some flows
/// check intermediate frames.
Future<void> tapSettingsRow(WidgetTester tester, String label) async {
  final settingsList = find.byKey(const ValueKey('settingsList'));
  if (settingsList.evaluate().isEmpty) {
    await tester.tap(find.byKey(const ValueKey('homeSettingsDestination')));
    await tester.pumpAndSettle();
  }
  final row = find.text(label);
  await tester.scrollUntilVisible(
    row,
    100,
    scrollable: find.descendant(
      of: settingsList,
      matching: find.byType(Scrollable),
    ),
  );
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
}
