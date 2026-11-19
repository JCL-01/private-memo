import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'notes_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final notesRepositoryProvider = Provider<NotesRepository>(
  (ref) => NotesRepository(ref.watch(databaseProvider)),
);

final notesListProvider = StreamProvider<List<Note>>(
  (ref) => ref.watch(notesRepositoryProvider).watchAll(),
);
