import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:holy_quran_app/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HolyQuranApp()));

    expect(find.text('Holy Quran Reading App'), findsOneWidget);
    expect(find.text('Digital Sanctuary'), findsOneWidget);
  });
}
