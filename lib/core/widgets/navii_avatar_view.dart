import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:navii_dart/navii_dart.dart' as navii;

/// Adapter around the `navii_dart` package — screens depend only on this,
/// never on `package:navii_dart` directly, so a future API change (or a
/// different avatar engine) only touches this file.
///
/// `navii_dart` is a pure-Dart deterministic SVG generator (same seed =
/// byte-identical SVG, entirely local, no network call), so unlike SORTA's
/// hand-rolled `NaviiAvatar` (which fetches a PNG over HTTP) this renders
/// instantly and works offline.
class NaviiAvatarView extends StatelessWidget {
  final String seed;
  final double size;

  /// Kept for call-site parity with SORTA's NaviiAvatar; navii_dart's output
  /// is a static SVG, so this has no effect yet.
  final bool animated;

  const NaviiAvatarView({
    super.key,
    required this.seed,
    required this.size,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedSeed = seed.trim().isEmpty ? 'default' : seed.trim();
    final svg = navii.createAvatar(
      resolvedSeed,
      navii.AvatarOptions(size: size),
    );
    return ClipOval(
      child: SvgPicture.string(
        _stripUnsupportedFilters(svg),
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }

  /// flutter_svg can't render SVG `<filter>` elements (navii_dart emits one
  /// for its hue-rotate effect on some seeds), which just logs "unhandled
  /// element `<filter/>`" and otherwise renders that part in its base color
  /// anyway — strip it up front so the console stays quiet with no visual
  /// change.
  static String _stripUnsupportedFilters(String svg) {
    return svg
        .replaceAll(RegExp(r'<filter[^>]*>.*?</filter>'), '')
        .replaceAll(RegExp(r'\s*filter="url\(#[^)]*\)"'), '');
  }
}
