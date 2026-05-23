import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:holy_quran_app/presentation/app.dart';

void main() {
  testWidgets('App widget tree builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HolyQuranApp()));
    await tester.pump();

    // App renders — loading screen or home screen should be present
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
