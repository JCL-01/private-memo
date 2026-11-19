import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/database.dart';
import '../../data/note.dart';
import '../../data/providers.dart';
import 'date_label.dart';
import 'note_editor_screen.dart';

class NoteListScreen extends ConsumerWidget {
  const NoteListScreen({super.key});

  Future<void> _createNote(BuildContext context, WidgetRef ref) async {
    final note = await ref.read(notesRepositoryProvider).create();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: note.id)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesListProvider);
    final count = notes.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('메모'),
        centerTitle: false,
        titleTextStyle: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      body: notes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('메모를 불러오지 못했습니다.\n$e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('메모 없음'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: list.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (_, i) => _NoteTile(note: list[i]),
              ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                count == 0 ? '메모 없음' : '$count개의 메모',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              key: const Key('newNoteButton'),
              tooltip: '새로운 메모',
              icon: const Icon(Icons.edit_square),
              onPressed: () => _createNote(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteTile extends ConsumerWidget {
  const _NoteTile({required this.note});

  final Note note;

  Future<void> _showMenu(
    BuildContext context,
    WidgetRef ref,
    Offset position,
  ) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: const [
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
    if (selected == 'delete') {
      await ref.read(notesRepositoryProvider).delete(note.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => ref.read(notesRepositoryProvider).delete(note.id),
      child: GestureDetector(
        // 모바일: 길게 누르기, PC: 우클릭 → 삭제 메뉴
        onLongPressStart: (d) => _showMenu(context, ref, d.globalPosition),
        onSecondaryTapUp: (d) => _showMenu(context, ref, d.globalPosition),
        child: ListTile(
          title: Text(
            note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: formatNoteDate(note.updatedAt)),
                const TextSpan(text: '  '),
                TextSpan(
                  text: note.preview.isEmpty ? '추가 텍스트 없음' : note.preview,
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: subtitleStyle,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NoteEditorScreen(noteId: note.id),
            ),
          ),
        ),
      ),
    );
  }
}
