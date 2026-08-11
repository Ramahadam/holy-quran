import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists a random installation identifier used only for API rate limiting.
class CloudflareClientIdStore {
  static const preferenceKey = 'cloudflare_client_id_v1';
  static final _validClientId = RegExp(r'^[a-f0-9]{32}$');

  final Random _random;
  Future<String>? _clientId;

  CloudflareClientIdStore({Random? random})
    : _random = random ?? Random.secure();

  Future<String> getOrCreate() {
    return _clientId ??= _loadOrCreate();
  }

  Future<String> _loadOrCreate() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(preferenceKey);
    if (existing != null && _validClientId.hasMatch(existing)) {
      return existing;
    }

    final clientId = List.generate(
      16,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await preferences.setString(preferenceKey, clientId);
    return clientId;
  }
}
