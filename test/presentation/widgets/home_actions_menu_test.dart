import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/presentation/theme/app_theme.dart';
import 'package:holy_quran_app/presentation/widgets/home_actions_menu.dart';

void main() {
  testWidgets('dispatches the selected Home action', (tester) async {
    var feedbackRequests = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          appBar: AppBar(
            actions: [
              HomeActionsMenu(
                darkModeEnabled: false,
                onSwitchLanguage: () {},
                onToggleDarkMode: () {},
                onOpenReminders: () {},
                onSendFeedback: () => feedbackRequests += 1,
                onSaveBackup: () {},
                onShareBackup: () {},
                onRestoreBackup: () {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('homeMenu-feedback')));
    await tester.pumpAndSettle();

    expect(feedbackRequests, 1);
  });
}
