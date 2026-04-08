import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/coach/coach_note.dart';
import '../../services/coach/coach_storage_service.dart';

final coachNotesControllerProvider =
    AsyncNotifierProvider<CoachNotesController, List<CoachNote>>(
  CoachNotesController.new,
);

class CoachNotesController extends AsyncNotifier<List<CoachNote>> {
  static const _uuid = Uuid();

  @override
  Future<List<CoachNote>> build() async {
    await _ensureDeviceId();
    return _loadVisibleNotes();
  }

  Future<void> refresh() async {
    await reload();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    await _ensureDeviceId();
    state = AsyncData(await _loadVisibleNotes());
  }

  Future<void> addNote({
    required String clientId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final deviceId = await _ensureDeviceId();
    final existing = state.value ?? await _loadVisibleNotes();

    final now = DateTime.now();
    final note = CoachNote(
      noteId: _newId(),
      clientId: clientId,
      text: trimmed,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      version: 1,
      updatedByDeviceId: deviceId,
    );

    final updated = [note, ...existing]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    await CoachStorageService.saveNotes(updated);
    state = AsyncData(updated);
  }

  Future<void> updateNote({
    required String noteId,
    required String newText,
  }) async {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;

    final deviceId = await _ensureDeviceId();
    final existing = state.value ?? await _loadVisibleNotes();

    final now = DateTime.now();
    final updated = existing.map((n) {
      if (n.noteId != noteId) return n;

      return CoachNote(
        noteId: n.noteId,
        clientId: n.clientId,
        text: trimmed,
        createdAt: n.createdAt,
        updatedAt: now,
        deletedAt: n.deletedAt,
        version: n.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    await CoachStorageService.saveNotes(updated);
    state = AsyncData(updated);
  }

  Future<void> deleteNote(String noteId) async {
    final deviceId = await _ensureDeviceId();
    final now = DateTime.now();

    final allStored = await CoachStorageService.loadNotes();

    final updatedAll = allStored.map((n) {
      if (n.noteId != noteId) return n;

      return n.copyWith(
        updatedAt: now,
        deletedAt: now,
        version: n.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList();

    await CoachStorageService.saveNotes(updatedAll);

    final visible = updatedAll.where((n) => !n.isDeleted).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    state = AsyncData(visible);
  }

  Future<List<CoachNote>> _loadVisibleNotes() async {
    final notes = await CoachStorageService.loadNotes();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes.where((n) => !n.isDeleted).toList();
  }

  Future<String> _ensureDeviceId() async {
    final existing = await CoachStorageService.loadDeviceId();

    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    final newId = _uuid.v4();
    await CoachStorageService.saveDeviceId(newId);
    return newId;
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}