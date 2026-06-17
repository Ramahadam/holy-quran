import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract class FeedbackPromptController {
  Future<void> recordReadingSession({DateTime? now});
  Future<bool> shouldPrompt({DateTime? now});
  Future<void> dismissPrompt({DateTime? now});
  Future<void> markFeedbackSubmitted({DateTime? now});
}

abstract class FeedbackPromptStore {
  Future<FeedbackPromptState> load();
  Future<void> save(FeedbackPromptState state);
}

class FeedbackPromptState {
  final int readingDayCount;
  final String? lastReadingDay;
  final int? firstReadingSessionEpochMillis;
  final int? dismissedUntilEpochMillis;
  final int? submittedAtEpochMillis;

  const FeedbackPromptState({
    this.readingDayCount = 0,
    this.lastReadingDay,
    this.firstReadingSessionEpochMillis,
    this.dismissedUntilEpochMillis,
    this.submittedAtEpochMillis,
  });

  factory FeedbackPromptState.fromJson(Map<String, Object?> json) {
    final readingDayCount = json['reading_day_count'];
    final lastReadingDay = json['last_reading_day'];
    final firstReadingSession = json['first_reading_session_epoch_millis'];
    final dismissedUntil = json['dismissed_until_epoch_millis'];
    final submittedAt = json['submitted_at_epoch_millis'];

    return FeedbackPromptState(
      readingDayCount: readingDayCount is int && readingDayCount > 0
          ? readingDayCount
          : 0,
      lastReadingDay: lastReadingDay is String ? lastReadingDay : null,
      firstReadingSessionEpochMillis: firstReadingSession is int
          ? firstReadingSession
          : null,
      dismissedUntilEpochMillis: dismissedUntil is int ? dismissedUntil : null,
      submittedAtEpochMillis: submittedAt is int ? submittedAt : null,
    );
  }

  Map<String, Object?> toJson() => {
    'reading_day_count': readingDayCount,
    'last_reading_day': lastReadingDay,
    'first_reading_session_epoch_millis': firstReadingSessionEpochMillis,
    'dismissed_until_epoch_millis': dismissedUntilEpochMillis,
    'submitted_at_epoch_millis': submittedAtEpochMillis,
  };
}

class SharedPreferencesFeedbackPromptStore implements FeedbackPromptStore {
  static const _stateKey = 'feedback_prompt_state_v1';

  final SharedPreferencesAsync _preferences;

  SharedPreferencesFeedbackPromptStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  @override
  Future<FeedbackPromptState> load() async {
    final source = await _preferences.getString(_stateKey);
    if (source == null) return const FeedbackPromptState();

    try {
      final json = jsonDecode(source);
      if (json is! Map<String, Object?>) {
        return const FeedbackPromptState();
      }
      return FeedbackPromptState.fromJson(json);
    } on FormatException {
      return const FeedbackPromptState();
    } on ArgumentError {
      return const FeedbackPromptState();
    }
  }

  @override
  Future<void> save(FeedbackPromptState state) {
    return _preferences.setString(_stateKey, jsonEncode(state.toJson()));
  }
}

class FeedbackPromptService implements FeedbackPromptController {
  static const requiredReadingDays = 7;
  static const promptCooldown = Duration(days: 30);

  final FeedbackPromptStore _store;
  final Duration? _testPromptDelay;

  FeedbackPromptService({
    required FeedbackPromptStore store,
    Duration? testPromptDelay,
  }) : _store = store,
       _testPromptDelay = testPromptDelay;

  @override
  Future<void> recordReadingSession({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final currentDay = _localDayKey(currentTime);
    final state = await _store.load();

    if (state.lastReadingDay == currentDay) return;

    await _store.save(
      FeedbackPromptState(
        readingDayCount: state.readingDayCount + 1,
        lastReadingDay: currentDay,
        firstReadingSessionEpochMillis:
            state.firstReadingSessionEpochMillis ??
            currentTime.millisecondsSinceEpoch,
        dismissedUntilEpochMillis: state.dismissedUntilEpochMillis,
        submittedAtEpochMillis: state.submittedAtEpochMillis,
      ),
    );
  }

  @override
  Future<bool> shouldPrompt({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final state = await _store.load();

    if (state.submittedAtEpochMillis != null) return false;
    final testPromptDelay = _testPromptDelay;
    if (testPromptDelay != null) {
      final firstSession = state.firstReadingSessionEpochMillis;
      if (firstSession == null) return false;
      if (currentTime.isBefore(
        DateTime.fromMillisecondsSinceEpoch(firstSession).add(testPromptDelay),
      )) {
        return false;
      }
    } else if (state.readingDayCount < requiredReadingDays) {
      return false;
    }

    final dismissedUntil = state.dismissedUntilEpochMillis;
    if (dismissedUntil != null &&
        currentTime.isBefore(
          DateTime.fromMillisecondsSinceEpoch(dismissedUntil),
        )) {
      return false;
    }

    return true;
  }

  @override
  Future<void> dismissPrompt({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final state = await _store.load();

    await _store.save(
      FeedbackPromptState(
        readingDayCount: state.readingDayCount,
        lastReadingDay: state.lastReadingDay,
        firstReadingSessionEpochMillis: state.firstReadingSessionEpochMillis,
        dismissedUntilEpochMillis: currentTime
            .add(promptCooldown)
            .millisecondsSinceEpoch,
        submittedAtEpochMillis: state.submittedAtEpochMillis,
      ),
    );
  }

  @override
  Future<void> markFeedbackSubmitted({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final state = await _store.load();

    await _store.save(
      FeedbackPromptState(
        readingDayCount: state.readingDayCount,
        lastReadingDay: state.lastReadingDay,
        firstReadingSessionEpochMillis: state.firstReadingSessionEpochMillis,
        dismissedUntilEpochMillis: state.dismissedUntilEpochMillis,
        submittedAtEpochMillis: currentTime.millisecondsSinceEpoch,
      ),
    );
  }

  String _localDayKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class DisabledFeedbackPromptController implements FeedbackPromptController {
  const DisabledFeedbackPromptController();

  @override
  Future<void> dismissPrompt({DateTime? now}) async {}

  @override
  Future<void> markFeedbackSubmitted({DateTime? now}) async {}

  @override
  Future<void> recordReadingSession({DateTime? now}) async {}

  @override
  Future<bool> shouldPrompt({DateTime? now}) async => false;
}
