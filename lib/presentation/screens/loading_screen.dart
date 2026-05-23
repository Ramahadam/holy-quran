import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quran_providers.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LoadingScreen extends ConsumerWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(initializeDataProvider);

    initState.whenData((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
    });

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 24,
                    color: AppTheme.islamicGreen,
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
            if (initState.isLoading)
              Text(
                'Preparing your Digital Sanctuary...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
