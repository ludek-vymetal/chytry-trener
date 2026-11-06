// Převod měření z váhy SPAL (FitMao) na InBody.
// Spuštění:  flutter test test/spal_mereni_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_application_1/features/spal/spal_mereni.dart';

void main() {
  test('kompletní měření z FitMao', () {
    final e = SpalMereniSync.prevest(
      {
        'id': 1234,
        'cas': '2026-11-05T07:30:00+00:00',
        'vyska_cm': 181,
        'hmotnost_kg': 84.6,
        'tuk_pct': 13.8,
        'tuk_kg': 11.7,
        'svaly_kg': 69.1,
        'kosterni_svaly_kg': 41.2,
        'voda_pct': 61.5,
        'voda_l': 52.0,
        'bilkoviny_kg': 14.3,
        'mineraly_kg': 4.1,
        'beztukova_kg': 72.9,
        'visceralni': 6,
        'bmi': 25.8,
        'bmr_kcal': 1945,
        'skore': 84,
        'telesny_vek': 27,
        'uprava_tuku_kg': -3.2,
        'uprava_svalu_kg': 1.5,
        'svaly_pp': 4.1,
        'svaly_lp': 4.0,
        'svaly_trup': 31.2,
        'svaly_pn': 11.4,
        'svaly_ln': 11.3,
        'tuk_pp': 0.6,
        'tuk_lp': 0.6,
        'tuk_trup': 5.9,
        'tuk_pn': 1.9,
        'tuk_ln': 1.9,
      },
      clientId: 'k1',
      heightCm: 180,
      deviceId: 'dev',
    )!;

    expect(e.clientId, 'k1');
    expect(e.isFromSpal, isTrue);
    expect(e.externalId, 'spal:1234');
    expect(e.heightCm, 181);
    expect(e.weightKg, 84.6);
    expect(e.leanMassKg, 72.9);
    expect(e.smmKg, 41.2);
    expect(e.bmr, 1945);
    expect(e.muscleRightArmKg, 4.1);
    expect(e.muscleLeftArmKg, 4.0);
    expect(e.fatTrunkKg, 5.9);
    expect(e.totalMuscleKg, 69.1);
    expect(e.proteinKg, 14.3);
    expect(e.mineralKg, 4.1);
    expect(e.bodyAge, 27);
    expect(e.waterPercent, 61.5);
    expect(e.fatControlKg, -3.2);
    expect(e.muscleControlKg, 1.5);
    expect(e.visceralFatLevel, 6);
    expect(e.inbodyScore, 84);

    // JSON tam a zpět (ukládání a synchronizace s trenérem)
    final back = e.toJson();
    expect(back['externalId'], 'spal:1234');
    expect(back['proteinKg'], 14.3);
  });

  test('jen hmotnost a % tuku – zbytek se dopočítá', () {
    final e = SpalMereniSync.prevest(
      {'id': '7', 'cas': '2026-11-05T07:30:00Z', 'hmotnost_kg': '80', 'tuk_pct': '20'},
      clientId: 'k1',
      heightCm: 180,
      deviceId: 'dev',
    )!;
    expect(e.fatKg, closeTo(16, 0.001));
    expect(e.leanMassKg, closeTo(64, 0.001));
    expect(e.bmi, closeTo(80 / (1.8 * 1.8), 0.001));
    expect(e.totalMuscleKg, isNull);
    expect(e.fatControlKg, isNull);
  });

  test('měření bez hmotnosti se přeskočí', () {
    expect(
      SpalMereniSync.prevest(
        {'id': 8, 'cas': '2026-11-05T07:30:00Z', 'hmotnost_kg': 0},
        clientId: 'k1',
        heightCm: 180,
        deviceId: 'dev',
      ),
      isNull,
    );
  });
}
