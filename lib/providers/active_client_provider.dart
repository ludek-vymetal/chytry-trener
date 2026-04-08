import 'package:flutter_riverpod/flutter_riverpod.dart';

/// aktuálně aktivní klient v aplikaci (user mód)
final activeClientIdProvider = StateProvider<String?>((ref) => null);
