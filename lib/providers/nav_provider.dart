import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vybraná záložka klientské aplikace (Dnes · Jídlo · Trénink · Pokrok ·
/// Profil) – aby šlo přepnout záložku i z karet na obrazovce Dnes.
final userTabProvider = StateProvider<int>((ref) => 0);

/// Vybraná záložka trenérského režimu (Přehled · Klienti · Nastavení).
final coachTabProvider = StateProvider<int>((ref) => 0);
