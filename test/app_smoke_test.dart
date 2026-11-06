import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_application_1/app.dart';

void main() {
  testWidgets('app starts', (tester) async {
    // Aplikace při startu spouští úlohy na pozadí (načítání profilu,
    // synchronizace, zálohy) s vlastními časovači. Ve „falešném čase“ testu
    // by zůstaly nevyřízené („A Timer is still pending“), proto se aplikace
    // spustí a zase zavře ve skutečném čase.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(find.byType(MyApp), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });
}
