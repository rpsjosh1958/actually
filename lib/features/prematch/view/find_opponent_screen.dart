import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/actually_challenge.dart';
import '../../../core/providers/actually_challenge_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/accent_button.dart';

/// Shown when the player has no in-flight challenge yet (or has one still
/// `pending`) — search-and-invite by username, mirroring SORTA-APP's
/// opponent-search flow (lib/features/versus/view/versus_screen.dart).
class FindOpponentScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const FindOpponentScreen({super.key, required this.onBack});

  @override
  ConsumerState<FindOpponentScreen> createState() => _FindOpponentScreenState();
}

class _FindOpponentScreenState extends ConsumerState<FindOpponentScreen> {
  final _usernameCtrl = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await ref
        .read(actuallyChallengeActionsProvider.notifier)
        .sendChallenge(_usernameCtrl.text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;
    final myUid = ref.watch(currentUserProvider)?.uid;
    final challenge = ref.watch(activeActuallyChallengeProvider).asData?.value;

    Widget body;
    if (challenge != null &&
        challenge.status == ActuallyChallengeStatus.pending) {
      body = challenge.challengerUid == myUid
          ? _WaitingCard(
              name: challenge.opponentName,
              challengeId: challenge.id,
            )
          : _IncomingCard(challenge: challenge);
    } else {
      body = _SearchForm(
        controller: _usernameCtrl,
        sending: _sending,
        error: _error,
        onSend: _send,
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Text(
                  '←',
                  style: textTheme.headline.copyWith(
                    fontSize: 22,
                    color: colors.paperText,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: Center(child: body)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchForm extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final String? error;
  final VoidCallback onSend;

  const _SearchForm({
    required this.controller,
    required this.sending,
    required this.error,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VERSUS',
          style: textTheme.wordmark.copyWith(
            fontSize: 36,
            color: colors.paperText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'swipe head-to-head against a real player',
          style: textTheme.bodyRegular.copyWith(color: colors.mutedText),
        ),
        const SizedBox(height: 26),
        Container(
          decoration: BoxDecoration(
            color: colors.paperBg,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextField(
            controller: controller,
            style: textTheme.body.copyWith(color: colors.paperText),
            decoration: InputDecoration(
              hintText: "opponent's username",
              hintStyle: textTheme.bodyRegular.copyWith(
                color: colors.faintText,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 20,
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            style: textTheme.bodyRegular.copyWith(
              color: colors.danger,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 20),
        AccentButton(
          label: 'SEND CHALLENGE',
          variant: AccentButtonVariant.ink,
          isLoading: sending,
          onTap: sending ? null : onSend,
        ),
      ],
    );
  }
}

class _WaitingCard extends StatelessWidget {
  final String name;
  final String challengeId;

  const _WaitingCard({required this.name, required this.challengeId});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;
    return Consumer(
      builder: (context, ref, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'waiting for $name to accept…',
            style: textTheme.headline.copyWith(
              fontSize: 22,
              color: colors.paperText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          AccentButton(
            label: 'CANCEL',
            variant: AccentButtonVariant.outline,
            onTap: () => ref
                .read(actuallyChallengeActionsProvider.notifier)
                .cancelChallenge(challengeId),
          ),
        ],
      ),
    );
  }
}

class _IncomingCard extends StatelessWidget {
  final ActuallyChallenge challenge;

  const _IncomingCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;
    return Consumer(
      builder: (context, ref, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${challenge.challengerName} challenged you!',
            style: textTheme.headline.copyWith(
              fontSize: 22,
              color: colors.paperText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'swipe head-to-head, first to bust more myths wins',
            style: textTheme.bodyRegular.copyWith(color: colors.mutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          AccentButton(
            label: 'ACCEPT',
            variant: AccentButtonVariant.accent,
            onTap: () => ref
                .read(actuallyChallengeActionsProvider.notifier)
                .acceptChallenge(challenge.id),
          ),
          const SizedBox(height: 10),
          AccentButton(
            label: 'DECLINE',
            variant: AccentButtonVariant.outline,
            onTap: () => ref
                .read(actuallyChallengeActionsProvider.notifier)
                .declineChallenge(challenge.id),
          ),
        ],
      ),
    );
  }
}
