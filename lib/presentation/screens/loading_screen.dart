import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quran_providers.dart';
import '../theme/app_theme.dart';
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
    ref.listenManual<AsyncValue<void>>(
      initializeDataProvider,
      (_, next) {
        if (next is AsyncData && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      },
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final initState = ref.watch(initializeDataProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            initState.when(
              data: (_) => const Icon(
                Icons.check_circle_outline,
                color: AppTheme.islamicGreen,
                size: 48,
              ),
              loading: () => const CircularProgressIndicator(
                color: AppTheme.islamicGreen,
              ),
              error: (e, _) => Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load data.\nPlease restart the app.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Preparing your Digital Sanctuary...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
