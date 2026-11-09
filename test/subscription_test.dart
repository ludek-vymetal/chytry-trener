// Úrovně přístupu: Klient PRO / Trenér PRO / klient trenéra / zkouška.
// Spuštění:  flutter test test/subscription_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_application_1/providers/subscription/subscription_provider.dart';

void main() {
  test('Klient PRO: plný uživatelský mód, trenér jen 1 klient', () {
    const s = SubscriptionStatus(plan: AppPlan.pro, tier: AppTier.klient);
    expect(s.isFull, isTrue);
    expect(s.fullMealPlan, isTrue);
    expect(s.coachFull, isFalse);
    expect(s.maxClients, 1);
    expect(s.label, 'Klient PRO');
  });

  test('Trenér PRO: vše bez omezení', () {
    const s = SubscriptionStatus(plan: AppPlan.pro, tier: AppTier.trener);
    expect(s.isFull, isTrue);
    expect(s.coachFull, isTrue);
    expect(s.maxClients, isNull);
  });

  test('klient trenéra: plný uživatelský mód zdarma', () {
    const s = SubscriptionStatus(plan: AppPlan.coached, coachName: 'Luděk');
    expect(s.isFull, isTrue);
    expect(s.shoppingList, isTrue);
    expect(s.coachFull, isFalse);
    expect(s.label, contains('Luděk'));
  });

  test('zkouška: vše odemčené, i před spuštěním', () {
    const s = SubscriptionStatus(plan: AppPlan.trial);
    expect(s.isFull, isTrue);
    expect(s.coachFull, isTrue);
    expect(s.daysLeft, isNull);
  });

  test('po zkoušce: omezená verze', () {
    const s = SubscriptionStatus(plan: AppPlan.free);
    expect(s.isFull, isFalse);
    expect(s.maxClients, 1);
    expect(s.cleanPdf, isFalse);
  });

  test('starý kód bez druhu = Trenér PRO', () {
    expect(tierFromString(null), AppTier.trener);
    expect(tierFromString('klient'), AppTier.klient);
  });
}
