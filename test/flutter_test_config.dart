import 'dart:async';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // On macOS hosts path_provider resolves real app directories through FFI;
  // tests must not write there, so every path lookup fails as on a bare VM.
  PathProviderPlatform.instance = _NoPathProvider();
  await testMain();
}

class _NoPathProvider extends PathProviderPlatform {}
