import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/local/isar_service.dart';
import 'presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
