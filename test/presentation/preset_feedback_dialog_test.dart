import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/feedback/anonymous_feedback_service.dart';
import 'package:holy_quran_app/l10n/app_localizations.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/presentation/theme/app_theme.dart';
import 'package:holy_quran_app/presentation/widgets/home_feedback_dialog.dart';

Finder _button(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((widget) => widget is FilledButton),
);

Future<void> _openDialog(
  WidgetTester tester, {
  String locale = 'en',
  double scale = 1,
  _FeedbackService? service,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (service != null)
          anonymousFeedbackServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: locale == 'ar' ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => const HomeFeedbackDialog(),
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
}

void main() {
  testWidgets(
    'feedback has no text entry and requires a choice before sending',
    (tester) async {
      await _openDialog(tester);
      expect(find.byType(EditableText), findsNothing);
      expect(tester.widget<FilledButton>(_button('Send')).onPressed, isNull);
      await tester.tap(
        find.byKey(const ValueKey('feedbackChoice-reading_display')),
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(_button('Send')).onPressed, isNotNull);
    },
  );

  for (final locale in ['en', 'ar']) {
    testWidgets('all choices reachable at 320px with 2x text in $locale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _openDialog(tester, locale: locale, scale: 2);
      expect(find.byType(EditableText), findsNothing);
      for (final choice in FeedbackChoice.values) {
        final tile = find.byKey(ValueKey('feedbackChoice-${choice.code}'));
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        await tester.tap(tile);
        await tester.pump();
        expect(
          tester
              .widget<RadioGroup<FeedbackChoice>>(
                find.byType(RadioGroup<FeedbackChoice>),
              )
              .groupValue,
          choice,
        );
      }
      expect(
        tester
            .widget<FilledButton>(_button(locale == 'ar' ? 'إرسال' : 'Send'))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'locks choices during sending and preserves selection for retry',
    (tester) async {
      final service = _FeedbackService();
      await _openDialog(tester, service: service);
      await tester.tap(
        find.byKey(const ValueKey('feedbackChoice-reading_display')),
      );
      await tester.pump();
      await tester.tap(find.text('Send'));
      await tester.pump();
      expect(service.submissions, [FeedbackChoice.readingDisplay]);
      expect(tester.widget<FilledButton>(_button('Sending')).onPressed, isNull);
      for (final tile in tester.widgetList<RadioListTile<FeedbackChoice>>(
        find.byType(RadioListTile<FeedbackChoice>),
      )) {
        expect(tile.enabled, isFalse);
      }
      service.pending.completeError(const FeedbackSubmissionException());
      await tester.pumpAndSettle();
      expect(
        find.text('Feedback could not be sent. Please try again later.'),
        findsOneWidget,
      );
      service.pending = Completer<void>();
      await tester.tap(find.text('Send'));
      await tester.pump();
      expect(service.submissions, [
        FeedbackChoice.readingDisplay,
        FeedbackChoice.readingDisplay,
      ]);
      service.pending.complete();
      await tester.pumpAndSettle();
      expect(find.byType(HomeFeedbackDialog), findsNothing);
      expect(find.text('Feedback sent'), findsOneWidget);
    },
  );
}

class _FeedbackService extends AnonymousFeedbackService {
  _FeedbackService() : super(transport: const UnconfiguredFeedbackTransport());
  Completer<void> pending = Completer<void>();
  final submissions = <FeedbackChoice>[];
  @override
  Future<void> submitFeedback(
    FeedbackChoice choice, {
    FeedbackMetadata? metadata,
  }) {
    submissions.add(choice);
    return pending.future;
  }
}
