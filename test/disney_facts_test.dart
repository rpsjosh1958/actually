import 'package:flutter_test/flutter_test.dart';

import 'package:actually/core/data/fact_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Disney deck loads from the bundled asset and is well-formed', () async {
    final facts = await FactRepository().loadDisney();

    expect(facts, isNotEmpty);
    expect(facts.map((f) => f.id).toSet(), hasLength(facts.length));
    expect(
      facts.every((f) => f.statement.trim().isNotEmpty && f.why.trim().isNotEmpty),
      isTrue,
    );
    // Both answers must be in the deck, or every swipe has the same answer.
    expect(facts.any((f) => f.isTrue), isTrue);
    expect(facts.any((f) => !f.isTrue), isTrue);
  });
}
