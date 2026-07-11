/// Pure, stateless helpers for the myth card — kept out of the widget layer
/// so the length-based sizing rule stays a plain function, not a token.
class PlayCardMetrics {
  const PlayCardMetrics._();

  /// Mirrors the prototype's length-based rule: shorter statements render
  /// bigger since they have room to breathe.
  static double fontSizeFor(String statement) {
    final len = statement.length;
    if (len < 55) return 30;
    if (len < 85) return 26;
    return 23;
  }

  /// CAP/BASED stamp opacity is a pure function of drag distance — fades in
  /// over the first 80px of drag, capped at 1.
  static double stampOpacity(double dragDx) => (dragDx.abs() / 80).clamp(0, 1);
}
