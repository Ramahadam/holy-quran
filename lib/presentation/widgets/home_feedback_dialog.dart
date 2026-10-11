import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/feedback/anonymous_feedback_service.dart';
import '../../l10n/l10n.dart';
import '../providers/quran_providers.dart';
import 'home_dialog.dart';

enum HomeFeedbackPromptAction { notNow, giveFeedback }

class HomeFeedbackPromptDialog extends StatelessWidget {
  const HomeFeedbackPromptDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeDialog(
      dialogKey: const ValueKey('homeDialog-feedbackPrompt'),
      headerKey: const ValueKey('homeDialogHeader-feedbackPrompt'),
      icon: Icons.favorite_border_rounded,
      title: context.l10n.feedbackPromptTitle,
      subtitle: context.l10n.feedbackPromptSubtitle,
      content: Text(context.l10n.feedbackPromptBody),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(72, 44)),
          onPressed: () =>
              Navigator.of(context).pop(HomeFeedbackPromptAction.notNow),
          child: Text(context.l10n.notNow),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(136, 44)),
          onPressed: () =>
              Navigator.of(context).pop(HomeFeedbackPromptAction.giveFeedback),
          icon: const Icon(Icons.feedback_outlined),
          label: Text(context.l10n.giveFeedback),
        ),
      ],
    );
  }
}

class HomeFeedbackDialog extends ConsumerStatefulWidget {
  final Future<void> Function()? onSubmitted;

  const HomeFeedbackDialog({super.key, this.onSubmitted});

  @override
  ConsumerState<HomeFeedbackDialog> createState() => _HomeFeedbackDialogState();
}

class _HomeFeedbackDialogState extends ConsumerState<HomeFeedbackDialog> {
  FeedbackChoice? _choice;
  bool _submitting = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;

    return HomeDialog(
      dialogKey: const ValueKey('homeDialog-feedback'),
      headerKey: const ValueKey('homeDialogHeader-feedback'),
      icon: Icons.feedback_outlined,
      title: l10n.sendFeedback,
      subtitle: l10n.feedbackSubtitle,
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioGroup<FeedbackChoice>(
            groupValue: _choice,
            onChanged: (choice) => setState(() {
              _choice = choice;
              _errorText = null;
            }),
            child: Column(
              children: [
                for (final choice in FeedbackChoice.values)
                  RadioListTile<FeedbackChoice>(
                    key: ValueKey('feedbackChoice-${choice.code}'),
                    value: choice,
                    enabled: !_submitting,
                    contentPadding: EdgeInsets.zero,
                    title: Text(switch (choice) {
                      FeedbackChoice.readingDisplay =>
                        l10n.feedbackReadingDisplay,
                      FeedbackChoice.translationTafsir =>
                        l10n.feedbackTranslationTafsir,
                      FeedbackChoice.reminders => l10n.feedbackReminders,
                      FeedbackChoice.appProblem => l10n.feedbackAppProblem,
                      FeedbackChoice.suggestion => l10n.feedbackSuggestion,
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          HomeDialogNotice(
            noticeKey: const ValueKey('feedbackPrivacyNotice'),
            icon: Icons.privacy_tip_outlined,
            text: l10n.feedbackPrivacy,
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                _errorText!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        if (_submitting)
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(l10n.sending),
              ],
            ),
          )
        else
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: _choice == null ? null : _submit,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(l10n.send),
          ),
      ],
    );
  }

  Future<void> _submit() async {
    final choice = _choice;
    if (choice == null || _submitting) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await ref.read(anonymousFeedbackServiceProvider).submitFeedback(choice);
      try {
        await widget.onSubmitted?.call();
      } catch (error) {
        debugPrint('Failed to mark feedback prompt submitted: $error');
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.feedbackSent),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      debugPrint('Failed to submit anonymous feedback: $error');
      setState(() {
        _errorText = context.l10n.feedbackSendFailed;
        _submitting = false;
      });
    }
  }
}
