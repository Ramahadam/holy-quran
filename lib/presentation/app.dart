import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/isar_service.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import 'providers/locale_provider.dart';
import 'providers/quran_providers.dart';
import 'providers/theme_mode_provider.dart';
import 'screens/loading_screen.dart';
import 'theme/app_theme.dart';

class HolyQuranApp extends ConsumerStatefulWidget {
  const HolyQuranApp({super.key});

  @override
  ConsumerState<HolyQuranApp> createState() => _HolyQuranAppState();
}

class _HolyQuranAppState extends ConsumerState<HolyQuranApp>
    with WidgetsBindingObserver {
  Future<void>? _timezoneSynchronization;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _synchronizeTimezone();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _synchronizeTimezone();
    }
  }

  void _synchronizeTimezone() {
    if (_timezoneSynchronization != null) return;

    final synchronization = _runTimezoneSynchronization();
    _timezoneSynchronization = synchronization;
    unawaited(
      synchronization.whenComplete(() {
        if (identical(_timezoneSynchronization, synchronization)) {
          _timezoneSynchronization = null;
        }
      }),
    );
  }

  Future<void> _runTimezoneSynchronization() async {
    try {
      await ref.read(prayerReminderTimezoneSynchronizerProvider)();
    } catch (error, stackTrace) {
      debugPrint('Reminder timezone synchronization failed: $error');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(appLocaleProvider);

    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const LoadingScreen(),
    );
  }
}

class DatabaseErrorApp extends ConsumerStatefulWidget {
  final Future<void> Function()? retryDatabase;

  const DatabaseErrorApp({super.key, this.retryDatabase});

  @override
  ConsumerState<DatabaseErrorApp> createState() => _DatabaseErrorAppState();
}

class _DatabaseErrorAppState extends ConsumerState<DatabaseErrorApp> {
  bool _retrying = false;
  bool _recovered = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);

    try {
      final retryDatabase = widget.retryDatabase;
      if (retryDatabase == null) {
        await IsarService.getInstance();
      } else {
        await retryDatabase();
      }
      if (mounted) setState(() => _recovered = true);
    } catch (error, stackTrace) {
      debugPrint('Database retry failed: $error');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_recovered) return const HolyQuranApp();

    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(appLocaleProvider);

    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.databaseError,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('databaseRetryButton'),
                    onPressed: _retrying ? null : _retry,
                    child: _retrying
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
