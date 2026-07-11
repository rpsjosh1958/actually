import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/actually_fact_submission_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/accent_button.dart';

/// Lets a player propose a new myth for the fact bank — statement, whether
/// it's true or false, and the reason — which then goes to a vote (see
/// `vote_queue_screen.dart`).
class SubmitFactScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const SubmitFactScreen({super.key, required this.onBack});

  @override
  ConsumerState<SubmitFactScreen> createState() => _SubmitFactScreenState();
}

class _SubmitFactScreenState extends ConsumerState<SubmitFactScreen> {
  final _statementCtrl = TextEditingController();
  final _whyCtrl = TextEditingController();
  bool? _isTrue;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _statementCtrl.dispose();
    _whyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isTrue == null) {
      setState(() => _error = "Pick CAP or BASED — is it true or false?");
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await ref
        .read(actuallyFactSubmissionActionsProvider)
        .submit(
          statement: _statementCtrl.text,
          isTrue: _isTrue!,
          why: _whyCtrl.text,
        );
    if (!mounted) return;
    if (error == null) {
      widget.onBack();
    } else {
      setState(() {
        _submitting = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
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
              const SizedBox(height: 18),
              Text(
                'SUBMIT A FACT',
                style: textTheme.headline.copyWith(
                  fontSize: 30,
                  color: colors.paperText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'get 10 players to agree and it joins the game.',
                style: textTheme.bodyRegular.copyWith(color: colors.mutedText),
              ),
              const SizedBox(height: 26),
              _Field(
                controller: _statementCtrl,
                hint: 'the myth (e.g. "goldfish have a 3-second memory")',
                colors: colors,
                textTheme: textTheme,
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _whyCtrl,
                hint: 'the reason it\'s true or false',
                colors: colors,
                textTheme: textTheme,
                maxLines: 3,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _VerdictChoice(
                      label: 'CAP',
                      selected: _isTrue == false,
                      background: colors.inkBg,
                      foreground: colors.inkText,
                      textTheme: textTheme,
                      onTap: () => setState(() => _isTrue = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _VerdictChoice(
                      label: 'BASED',
                      selected: _isTrue == true,
                      background: colors.accent,
                      foreground: colors.paperText,
                      textTheme: textTheme,
                      onTap: () => setState(() => _isTrue = true),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: textTheme.bodyRegular.copyWith(
                    color: colors.danger,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AccentButton(
                label: 'SUBMIT',
                variant: AccentButtonVariant.ink,
                isLoading: _submitting,
                onTap: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerdictChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final Color background;
  final Color foreground;
  final AppTextThemeExtension textTheme;
  final VoidCallback onTap;

  const _VerdictChoice({
    required this.label,
    required this.selected,
    required this.background,
    required this.foreground,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? background : background.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: textTheme.headline.copyWith(fontSize: 18, color: foreground),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final AppColorsExtension colors;
  final AppTextThemeExtension textTheme;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.hint,
    required this.colors,
    required this.textTheme,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.paperBg,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: textTheme.body.copyWith(color: colors.paperText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: textTheme.bodyRegular.copyWith(color: colors.faintText),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
