// test/widgets/glass_card_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/glass_card.dart';
import 'package:app/widgets/accent_pill.dart';
import 'package:app/widgets/pace_button.dart';

void main() {
  testWidgets('GlassCard renders child content', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: GlassCard(child: Text('Hello'))),
    ));
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('AccentPill renders label', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AccentPill(label: 'EASY')),
    ));
    expect(find.text('EASY'), findsOneWidget);
  });

  testWidgets('PaceButton calls onPressed', (tester) async {
    var pressed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PaceButton(
          label: 'Start',
          onPressed: () => pressed = true,
        ),
      ),
    ));
    await tester.tap(find.text('Start'));
    expect(pressed, true);
  });
}
