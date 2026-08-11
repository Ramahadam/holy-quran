import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/backend/cloudflare_client_id_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('creates and persists an opaque installation id', () async {
    final firstStore = CloudflareClientIdStore();
    final firstId = await firstStore.getOrCreate();
    final secondId = await CloudflareClientIdStore().getOrCreate();

    expect(firstId, matches(RegExp(r'^[a-f0-9]{32}$')));
    expect(secondId, firstId);
  });

  test('replaces a malformed persisted installation id', () async {
    SharedPreferences.setMockInitialValues({
      CloudflareClientIdStore.preferenceKey: 'not-a-client-id',
    });

    final clientId = await CloudflareClientIdStore().getOrCreate();

    expect(clientId, matches(RegExp(r'^[a-f0-9]{32}$')));
    expect(clientId, isNot('not-a-client-id'));
  });

  test('falls back when preferences do not respond', () async {
    final store = CloudflareClientIdStore(
      loadPreferences: () => Completer<SharedPreferences>().future,
      preferencesTimeout: Duration.zero,
    );

    final clientId = await store.getOrCreate();

    expect(clientId, matches(RegExp(r'^[a-f0-9]{32}$')));
    expect(await store.getOrCreate(), clientId);
  });

  testWidgets('dispose cancels a pending preferences timeout', (tester) async {
    final store = CloudflareClientIdStore(
      loadPreferences: () => Completer<SharedPreferences>().future,
    );

    unawaited(store.getOrCreate());
    store.dispose();
  });
}
