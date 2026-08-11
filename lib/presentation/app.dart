import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import 'providers/locale_provider.dart';
import 'providers/quran_providers.dart';
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

class DatabaseErrorApp extends ConsumerWidget {
  const DatabaseErrorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.databaseError,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
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
