import 'dart:async';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists a random installation identifier used only for API rate limiting.
class CloudflareClientIdStore {
  static const preferenceKey = 'cloudflare_client_id_v1';
  static final _validClientId = RegExp(r'^[a-f0-9]{32}$');

  final Random _random;
  final Future<SharedPreferences> Function() _loadPreferences;
  final Duration _preferencesTimeout;
  final Set<Timer> _pendingTimers = {};
  Future<String>? _clientId;

  CloudflareClientIdStore({
    Random? random,
    Future<SharedPreferences> Function()? loadPreferences,
    Duration preferencesTimeout = const Duration(seconds: 2),
  }) : _random = random ?? Random.secure(),
       _loadPreferences = loadPreferences ?? SharedPreferences.getInstance,
       _preferencesTimeout = preferencesTimeout;

  Future<String> getOrCreate() {
    return _clientId ??= _loadOrCreate();
  }

  void dispose() {
    for (final timer in _pendingTimers) {
      timer.cancel();
    }
    _pendingTimers.clear();
  }

  Future<String> _loadOrCreate() async {
    String? generatedClientId;
    try {
      final preferences = await _withTimeout(_loadPreferences());
      final existing = preferences.getString(preferenceKey);
      if (existing != null && _validClientId.hasMatch(existing)) {
        return existing;
      }

      generatedClientId = _generateClientId();
      await _withTimeout(
        preferences.setString(preferenceKey, generatedClientId),
      );
      return generatedClientId;
    } catch (_) {
      return generatedClientId ?? _generateClientId();
    }
  }

  String _generateClientId() {
    return List.generate(
      16,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<T> _withTimeout<T>(Future<T> operation) {
    final completer = Completer<T>();
    late final Timer timer;
    timer = Timer(_preferencesTimeout, () {
      _pendingTimers.remove(timer);
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Preferences did not respond.'),
        );
      }
    });
    _pendingTimers.add(timer);

    operation.then(
      (value) {
        timer.cancel();
        _pendingTimers.remove(timer);
        if (!completer.isCompleted) {
          completer.complete(value);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        timer.cancel();
        _pendingTimers.remove(timer);
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );

    return completer.future;
  }
}
