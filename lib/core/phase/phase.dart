enum PhaseType {
  gaining,
  cutting,
  peaking,
  maintenance,
}

extension PhaseTypeLabel on PhaseType {
  String get label {
    switch (this) {
      case PhaseType.gaining:
        return 'Nabírací fáze';
      case PhaseType.cutting:
        return 'Shazovací fáze';
      case PhaseType.peaking:
        return 'Rýsovací fáze';
      case PhaseType.maintenance:
        return 'Udržovací fáze';
    }
  }
}
