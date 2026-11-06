import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dart_application_1/app.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);

    // Aplikace při startu spouští zpožděné úlohy (načítání, synchronizace,
    // časové limity). Uklidit strom a nechat doběhnout jejich časovače,
    // jinak test spadne na „A Timer is still pending“.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  });
}