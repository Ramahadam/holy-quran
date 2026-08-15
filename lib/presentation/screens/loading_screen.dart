import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/l10n.dart';
import '../providers/quran_providers.dart';
import 'home_screen.dart';

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Listen once — navigate when data load completes, regardless of rebuilds.
    // fireImmediately: true ensures navigation fires even when the provider
    // is already settled before this widget mounts (e.g. hot-restart).
    ref.listenManual<AsyncValue<void>>(initializeDataProvider, (_, next) {
      if (next is AsyncData && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final initState = ref.watch(initializeDataProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontSize: 24,
                color: colors.primary,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            initState.when(
              data: (_) => Icon(
                Icons.check_circle_outline,
                color: colors.primary,
                size: 48,
              ),
              loading: () => CircularProgressIndicator(color: colors.primary),
              error: (e, _) => Column(
                children: [
                  Icon(Icons.error_outline, color: colors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.dataLoadError,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const ValueKey('quranDataRetryButton'),
                    onPressed: () => ref.invalidate(initializeDataProvider),
                    child: Text(context.l10n.retry),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.preparingApp,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
