class IdService {
  static String newId(String prefix) {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$ms';
  }
}
