import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/coach/coach_note.dart';
import 'coach_notes_controller.dart';

final coachNotesForClientProvider =
    Provider.family<AsyncValue<List<CoachNote>>, String>((ref, clientId) {
  final notesAsync = ref.watch(coachNotesControllerProvider);

  return notesAsync.whenData((notes) {
    final filtered = notes.where((n) => n.clientId == clientId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered;
  });
});
