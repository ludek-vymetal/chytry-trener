import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'food_catalog.dart';

/// Vlastní potraviny trenéra (název + makra na 100 g). Používají se
/// v editoru jídelníčku stejně jako potraviny z katalogu, takže se jim
/// makra počítají a porce přepočítávají automaticky.
class CustomFoodStore {
  CustomFoodStore._();

  static const key = 'custom_foods_v1';

  static List<NutritionFood> _foods = const [];

  /// Vlastní potraviny (načtené při startu aplikace).
  static List<NutritionFood> get foods => _foods;

  static Map<String, dynamic> toJson(NutritionFood f) => {
        'id': f.id,
        'name': f.name,
        'kcal': f.kcal,
        'protein': f.protein,
        'carbs': f.carbs,
        'fat': f.fat,
        'pieceGrams': f.pieceGrams,
      };

  static NutritionFood fromJson(Map<String, dynamic> j) {
    double n(Object? v) => (v as num?)?.toDouble() ?? 0;
    final piece = (j['pieceGrams'] as num?)?.toDouble();
    return NutritionFood(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      kcal: n(j['kcal']),
      protein: n(j['protein']),
      carbs: n(j['carbs']),
      fat: n(j['fat']),
      maxGrams: 2000,
      pieceGrams: (piece != null && piece > 0) ? piece : null,
      step: 5,
    );
  }

  static Future<List<NutritionFood>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    var list = <NutritionFood>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final d = jsonDecode(raw);
        if (d is List) {
          list = [
            for (final e in d)
              if (e is Map) fromJson(Map<String, dynamic>.from(e)),
          ];
        }
      } catch (_) {}
    }
    _foods = List.unmodifiable(list);
    return _foods;
  }

  static Future<List<NutritionFood>> save(List<NutritionFood> foods) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode([for (final f in foods) toJson(f)]));
    _foods = List.unmodifiable(foods);
    return _foods;
  }

  /// Nová potravina z hodnot na 100 g. Kalorie se dopočítají,
  /// když nejsou zadané.
  static NutritionFood create({
    required String name,
    required double protein,
    required double carbs,
    required double fat,
    double? kcal,
    double? pieceGrams,
  }) {
    final k = (kcal == null || kcal <= 0)
        ? protein * 4 + carbs * 4 + fat * 9
        : kcal;
    return NutritionFood(
      id: 'my_${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      kcal: k.roundToDouble(),
      protein: protein,
      carbs: carbs,
      fat: fat,
      maxGrams: 2000,
      pieceGrams: (pieceGrams != null && pieceGrams > 0) ? pieceGrams : null,
      step: 5,
    );
  }
}
