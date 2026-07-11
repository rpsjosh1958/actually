import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:actually/core/theme/app_theme.dart';
import 'package:actually/core/widgets/accent_button.dart';

void main() {
  testWidgets('AccentButton renders its label and responds to tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppThemeNotifier.light,
      home: Scaffold(
        body: AccentButton(label: 'SOLO STREAK', onTap: () => tapped = true),
      ),
    ));

    expect(find.text('SOLO STREAK'), findsOneWidget);

    await tester.tap(find.text('SOLO STREAK'));
    expect(tapped, isTrue);
  });
}
