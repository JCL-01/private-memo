import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/database.dart';
import '../../data/note.dart';
import '../../data/providers.dart';
import '../../editor/box_colors.dart';
import '../../editor/hidden_ranges.dart';
import '../../editor/masked_text.dart';
import '../folders/folder_dialogs.dart';
import 'date_label.dart';
import 'note_editor_screen.dart';

/// 새 메모를 [folderId] 폴더에 만들고 편집 화면을 연다.
Future<void> openNewNote(
  BuildContext context,
  WidgetRef ref,
  String folderId,
) async {
  final note = await ref
      .read(notesRepositoryProvider)
      .create(folderId: folderId);
  if (!context.mounted) return;
  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: note.id)));
}

/// 한 폴더의 메모 목록. (F1, F1F)
class NoteListScreen extends ConsumerWidget {
  const NoteListScreen({super.key, required this.folderId});

  final String folderId;

  bool get _isTrash => folderId == SystemFolders.trash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(folderNotesProvider(folderId));
    final folders = ref.watch(foldersProvider).value ?? const <Folder>[];
    final title =
        folders.where((f) => f.id == folderId).firstOrNull?.name ??
        SystemFolders.names[folderId] ??
        '';
    final count = notes.value?.length ?? 0;
    final countText = count == 0 ? '메모 없음' : '$count개의 메모';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
                _isTrash ? '$countText · 30일 후 영구 삭제' : countText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (_isTrash)
              const SizedBox(width: 48)
            else
              IconButton(
                key: const Key('newNoteButton'),
                tooltip: '새로운 메모',
                icon: const Icon(Icons.edit_square),
                onPressed: () => openNewNote(context, ref, folderId),
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

  bool get _inTrash => note.folderId == SystemFolders.trash;

  Future<void> _showMenu(
    BuildContext context,
    WidgetRef ref,
    Offset position,
  ) async {
    final repo = ref.read(notesRepositoryProvider);
    final choice = await showMenuAt<String>(
      context,
      position,
      _inTrash
          ? [
              menuItem('restore', Icons.restore, '복구'),
              menuItem(
                'purge',
                Icons.delete_forever_outlined,
                '영구 삭제',
                destructive: true,
              ),
            ]
          : [
              menuItem('move', Icons.drive_file_move_outline, '폴더로 이동'),
              menuItem('delete', Icons.delete_outline, '삭제', destructive: true),
            ],
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'restore':
        await repo.restore(note.id);
      case 'purge':
        await repo.delete(note.id);
      case 'delete':
        await repo.moveToTrash(note.id);
      case 'move':
        final target = await showMoveFolderSheet(
          context,
          ref,
          currentFolderId: note.folderId,
        );
        if (target != null) await repo.moveTo(note.id, target);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final hidden = note.displayHidden;
    final boxColor = boxColorOf(context);
    final titleLine = note.titleLine;
    final previewLine = note.previewLine;

    // 목록에서도 가린 부분은 박스로 보인다. (F1-7)
    final baseStyle = DefaultTextStyle.of(context).style
        .merge(theme.textTheme.bodyLarge);
    List<InlineSpan> masked(String text, List<HiddenRange> boxes) =>
        maskedSpans(
          text: text,
          boxes: boxes,
          boxColor: boxColor,
          style: baseStyle,
        );

    return Dismissible(
      key: ValueKey(note.id),
      // 최근 삭제된 항목에서는 밀어서 지우지 않는다(메뉴로 영구 삭제).
      direction: _inTrash ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) =>
          ref.read(notesRepositoryProvider).moveToTrash(note.id),
      child: GestureDetector(
        // 모바일: 길게 누르기, PC: 우클릭 → 메뉴
        onLongPressStart: (d) => _showMenu(context, ref, d.globalPosition),
        onSecondaryTapUp: (d) => _showMenu(context, ref, d.globalPosition),
        child: ListTile(
          title: Text.rich(
            titleLine == null
                ? const TextSpan(text: '새로운 메모')
                : TextSpan(
                    children: masked(
                      titleLine.text,
                      titleLine.hiddenIn(hidden),
                    ),
                  ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatNoteDate(
                    _inTrash
                        ? note.deletedAt ?? note.updatedAt
                        : note.updatedAt,
                  ),
                ),
                const TextSpan(text: '  '),
                if (previewLine == null)
                  const TextSpan(text: '추가 텍스트 없음')
                else
                  ...masked(previewLine.text, previewLine.hiddenIn(hidden)),
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
