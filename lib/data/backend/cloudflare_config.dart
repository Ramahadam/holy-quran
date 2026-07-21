const String cloudflareApiBaseUrl = String.fromEnvironment(
  'CLOUDFLARE_API_BASE_URL',
  defaultValue: 'https://holy-quran-api.mohamedadam-tech.workers.dev',
);

Uri? get configuredCloudflareApiBaseUri {
  final uri = Uri.tryParse(cloudflareApiBaseUrl);
  if (uri == null || !uri.hasAuthority) return null;
  if (uri.scheme != 'https' && uri.scheme != 'http') return null;
  return uri;
}
