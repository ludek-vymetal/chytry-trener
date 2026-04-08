enum TrainingSplit {
  auto,
  fullbody,
  upperLower,
  ppl,
  strength3day,
}

extension TrainingSplitLabel on TrainingSplit {
  String get label {
    switch (this) {
      case TrainingSplit.auto:
        return 'Automaticky';
      case TrainingSplit.fullbody:
        return 'Fullbody 3×';
      case TrainingSplit.upperLower:
        return 'Upper / Lower 4×';
      case TrainingSplit.ppl:
        return 'Push Pull Legs 6×';
      case TrainingSplit.strength3day:
        return 'Síla 3 dny';
    }
  }
}


