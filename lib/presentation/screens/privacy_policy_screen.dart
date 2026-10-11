import 'dart:convert';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  Future<String>? _policy;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.privacyPolicy)),
    body: FutureBuilder<String>(
      future: _policy ??= DefaultAssetBundle.of(
        context,
      ).loadString('assets/privacy/privacy_policy.json'),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(context.l10n.privacyPolicyUnavailable));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final policy = jsonDecode(snapshot.data!) as Map<String, dynamic>;
        final language = Localizations.localeOf(context).languageCode;
        final localized = policy[language == 'ar' ? 'ar' : 'en'] as Map;
        return SingleChildScrollView(
          key: const ValueKey('privacyPolicyBody'),
          padding: const EdgeInsets.all(24),
          child: SelectionArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(localized['updatedLabel'] as String),
                const SizedBox(height: 12),
                Text(policy['url'] as String, textDirection: TextDirection.ltr),
                for (final section in localized['sections'] as List) ...[
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text(
                      section['heading'] as String,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(section['body'] as String),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}
