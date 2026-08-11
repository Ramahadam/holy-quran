import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backend/cloudflare_client_id_store.dart';

final cloudflareClientIdStoreProvider = Provider<CloudflareClientIdStore>((
  ref,
) {
  return CloudflareClientIdStore();
});
