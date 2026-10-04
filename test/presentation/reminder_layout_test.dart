import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/notifications/prayer_reminder_settings.dart';
import 'package:holy_quran_app/l10n/app_localizations.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/presentation/widgets/home_prayer_reminder_dialog.dart';

void main() {
  for (final locale in ['en', 'ar']) {
    testWidgets(
      'reminder header and controls scroll together at 2x in $locale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              prayerReminderSettingsProvider.overrideWith(
                (ref) async => PrayerReminderSettings.defaults.copyWith(
                  enabled: true,
                  offsetMinutes: 25,
                  snoozeMinutes: 20,
                ),
              ),
            ],
            child: MaterialApp(
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const HomePrayerReminderDialog(),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
        expect(dialog.scrollable, isTrue);
        await tester.ensureVisible(
          find.byType(DropdownButtonFormField<int>).last,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final save = find.byKey(const ValueKey('reminderSaveAction'));
        expect(save.hitTestable(), findsOneWidget);
        final fields = tester
            .widgetList<DropdownButtonFormField<int>>(
              find.byType(DropdownButtonFormField<int>),
            )
            .toList();
        expect(fields[0].initialValue, 25);
        expect(fields[1].initialValue, 20);
      },
    );
  }
}
