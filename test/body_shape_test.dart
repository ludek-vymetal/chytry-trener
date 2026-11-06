// Tvar postavy z měření (jablko, hruška, silný vršek…).
// Spuštění:  flutter test test/body_shape_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_application_1/features/coach/clients/body_shape_figure.dart';
import 'package:dart_application_1/features/spal/spal_mereni.dart';

BodyShape _tvar(Map<String, dynamic> m, {bool male = true}) {
  final e = SpalMereniSync.prevest(
    {'id': 1, 'cas': '2026-11-05T07:00:00Z', ...m},
    clientId: 'k',
    heightCm: male ? 178 : 165,
    deviceId: 'd',
  )!;
  return BodyShape.fromEntry(e, male: male);
}

void main() {
  test('břišní tuk → jablko', () {
    final s = _tvar({
      'hmotnost_kg': 110, 'tuk_pct': 32, 'kosterni_svaly_kg': 36,
      'tuk_pp': 2, 'tuk_lp': 2, 'tuk_trup': 18, 'tuk_pn': 4, 'tuk_ln': 4,
      'svaly_pp': 3.8, 'svaly_lp': 3.8, 'svaly_trup': 28, 'svaly_pn': 10, 'svaly_ln': 10,
    });
    expect(s.shapeLabel, 'Jablko');
  });

  test('tuk na bocích a stehnech → hruška', () {
    final s = _tvar({
      'hmotnost_kg': 72, 'tuk_pct': 34, 'kosterni_svaly_kg': 24,
      'tuk_pp': 1.5, 'tuk_lp': 1.5, 'tuk_trup': 9, 'tuk_pn': 6.5, 'tuk_ln': 6.5,
      'svaly_pp': 2.2, 'svaly_lp': 2.2, 'svaly_trup': 19, 'svaly_pn': 8, 'svaly_ln': 8,
    }, male: false);
    expect(s.shapeLabel, 'Hruška');
  });

  test('silná horní polovina, slabší nohy', () {
    final s = _tvar({
      'hmotnost_kg': 90, 'tuk_pct': 13, 'kosterni_svaly_kg': 44,
      'tuk_pp': .6, 'tuk_lp': .6, 'tuk_trup': 5, 'tuk_pn': 1.8, 'tuk_ln': 1.8,
      'svaly_pp': 5.4, 'svaly_lp': 5.4, 'svaly_trup': 34, 'svaly_pn': 9.5, 'svaly_ln': 9.5,
    });
    expect(s.muscleLabel, 'Silný vršek, slabší nohy');
  });

  test('bez segmentů se tvar odhadne a nespadne', () {
    final s = _tvar({'hmotnost_kg': 80, 'tuk_pct': 18});
    expect(s.muscleLabel, contains('nejsou změřené'));
  });
}
