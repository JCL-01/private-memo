import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'folders_repository.dart';
import 'notes_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final notesRepositoryProvider = Provider<NotesRepository>(
  (ref) => NotesRepository(ref.watch(databaseProvider)),
);

final foldersRepositoryProvider = Provider<FoldersRepository>(
  (ref) => FoldersRepository(ref.watch(databaseProvider)),
);

/// 폴더 목록(기본 폴더 먼저).
final foldersProvider = StreamProvider<List<Folder>>(
  (ref) => ref.watch(foldersRepositoryProvider).watchAll(),
);

/// 폴더별 메모 개수.
final folderCountsProvider = StreamProvider<Map<String, int>>(
  (ref) => ref.watch(notesRepositoryProvider).watchCounts(),
);

/// 한 폴더의 메모 목록.
final folderNotesProvider = StreamProvider.family<List<Note>, String>(
  (ref, folderId) => ref.watch(notesRepositoryProvider).watchFolder(folderId),
);
