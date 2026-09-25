/// Stravovací omezení klienta.
enum DietPreference {
  /// Bez omezení (jí vše).
  none,

  /// Vegetarián: bez masa a ryb, mléčné výrobky a vejce ano.
  vegetarian,

  /// Vegan: bez jakýchkoli živočišných produktů.
  vegan,
}

extension DietPreferenceX on DietPreference {
  static DietPreference parse(String? raw) {
    for (final p in DietPreference.values) {
      if (p.name == raw) return p;
    }
    return DietPreference.none;
  }
}
