import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../view_model/play_card_metrics.dart';
import '../../view_model/play_view_model.dart';
import 'verdict_stamp.dart';

/// The draggable, flippable fact card — front face shows the statement and
/// fades in CAP/BASED stamps as you drag; committing (≥95px drag, or the
/// CAP/BASED buttons) flips to the back face with the verdict.
class MythCard extends ConsumerWidget {
  /// Called when the player taps the flipped-back card to move on. Null
  /// means the back face auto-advances on its own (battle mode) and
  /// shouldn't show a tap prompt or respond to taps.
  final VoidCallback? onContinueTap;

  const MythCard({super.key, required this.onContinueTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;
    final state = ref.watch(playViewModelProvider);
    final vm = ref.read(playViewModelProvider.notifier);
    final fact = state.currentFact;
    if (fact == null) return const SizedBox.shrink();

    final rotation = state.dragDx / 18 * math.pi / 180;
    final capOpacity = state.face == CardFace.back
        ? 0.0
        : PlayCardMetrics.stampOpacity(math.min(0, state.dragDx));
    final basedOpacity = state.face == CardFace.back
        ? 0.0
        : PlayCardMetrics.stampOpacity(math.max(0, state.dragDx));

    return GestureDetector(
      onPanUpdate: (details) =>
          vm.onDragUpdate(state.dragDx + details.delta.dx),
      onPanEnd: (_) => vm.onDragEnd(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330, maxHeight: 440),
        child: AnimatedContainer(
          duration: state.isDragging
              ? Duration.zero
              : const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translateByDouble(state.dragDx, state.dragDx.abs() * 0.04, 0, 1)
            ..rotateZ(rotation),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            tween: Tween(
              begin: 0,
              end: state.face == CardFace.back ? 1.0 : 0.0,
            ),
            builder: (context, flip, child) {
              final showBack = flip >= 0.5;
              final angle = flip * math.pi;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(angle),
                child: showBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _CardBack(
                          colors: colors,
                          why: fact.why,
                          isTrue: fact.isTrue,
                          isCorrect: state.isCorrect,
                          timedOut: state.timedOut,
                          onContinue: onContinueTap,
                        ),
                      )
                    : _CardFront(
                        colors: colors,
                        statement: fact.statement,
                        factNo: state.factIndex + 1,
                        secondsRemaining: state.cardSecondsRemaining,
                        capOpacity: capOpacity,
                        basedOpacity: basedOpacity,
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  final AppColorsExtension colors;
  final String statement;
  final int factNo;
  final int secondsRemaining;
  final double capOpacity;
  final double basedOpacity;

  const _CardFront({
    required this.colors,
    required this.statement,
    required this.factNo,
    required this.secondsRemaining,
    required this.capOpacity,
    required this.basedOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).appTextTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: colors.paperBg,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 46,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FACT',
                    style: textTheme.caption.copyWith(
                      color: colors.paperText.withValues(alpha: 0.55),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '№ $factNo',
                        style: textTheme.caption.copyWith(
                          color: colors.paperText.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _CountdownBadge(
                        colors: colors,
                        secondsRemaining: secondsRemaining,
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Text(
                    statement,
                    style: Theme.of(context).appTextTheme.body.copyWith(
                      fontSize: PlayCardMetrics.fontSizeFor(statement),
                      fontWeight: FontWeight.w700,
                      color: colors.paperText,
                      height: 1.18,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '← CAP',
                    style: textTheme.caption.copyWith(
                      color: colors.paperText.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    'BASED →',
                    style: textTheme.caption.copyWith(
                      color: colors.paperText.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 22,
            left: 18,
            child: VerdictStamp(
              label: 'CAP',
              opacity: capOpacity,
              angleDegrees: -13,
              background: colors.inkBg,
              foreground: colors.inkText,
            ),
          ),
          Positioned(
            top: 22,
            right: 18,
            child: VerdictStamp(
              label: 'BASED',
              opacity: basedOpacity,
              angleDegrees: 12,
              background: colors.accent,
              foreground: colors.paperText,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  final AppColorsExtension colors;
  final int secondsRemaining;

  const _CountdownBadge({required this.colors, required this.secondsRemaining});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).appTextTheme;
    final urgent = secondsRemaining <= 3;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: urgent
              ? colors.danger
              : colors.paperText.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Text(
        '$secondsRemaining',
        style: textTheme.caption.copyWith(
          fontSize: 11,
          color: urgent
              ? colors.danger
              : colors.paperText.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final AppColorsExtension colors;
  final String why;
  final bool isTrue;
  final bool isCorrect;
  final bool timedOut;
  final VoidCallback? onContinue;

  const _CardBack({
    required this.colors,
    required this.why,
    required this.isTrue,
    required this.isCorrect,
    required this.timedOut,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).appTextTheme;
    final verdictWord = timedOut ? 'TOO SLOW.' : (isTrue ? 'BASED.' : 'CAP.');
    final verdictColor = timedOut
        ? colors.danger
        : (isTrue ? colors.accent : colors.inkText);
    final resultLine = timedOut
        ? "didn't swipe in time."
        : (isCorrect ? 'you called it. sharp.' : 'you got played.');

    return GestureDetector(
      onTap: onContinue,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        decoration: BoxDecoration(
          color: colors.inkBg,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 46,
              offset: const Offset(0, 22),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              verdictWord,
              style: textTheme.verdict.copyWith(color: verdictColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              resultLine,
              style: textTheme.label.copyWith(color: colors.inkText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              why,
              style: textTheme.bodyRegular.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            if (onContinue != null) ...[
              const SizedBox(height: 16),
              Text(
                'TAP TO CONTINUE →',
                style: textTheme.caption.copyWith(color: Colors.white38),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
