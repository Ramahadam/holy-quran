import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/local/isar_service.dart';
import 'presentation/app.dart';
import 'presentation/providers/quran_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isSupabaseFeedbackConfigured) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: configuredSupabaseKey,
      );
    } catch (e) {
      debugPrint('Feedback initialization failed: $e');
    }
  }

  bool dbFailed = false;
  try {
    await IsarService.getInstance();
  } catch (e, stackTrace) {
    debugPrint('Database initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    dbFailed = true;
  }

  runApp(
    ProviderScope(
      child: dbFailed ? const DatabaseErrorApp() : const HolyQuranApp(),
    ),
  );
}
