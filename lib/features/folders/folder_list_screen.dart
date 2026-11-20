import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/database.dart';
import '../../data/providers.dart';
import '../notes/note_list_screen.dart';
import 'folder_dialogs.dart';

/// 첫 화면: 폴더 목록. (F1F-1)
class FolderListScreen extends ConsumerStatefulWidget {
  const FolderListScreen({super.key});

  @override
  ConsumerState<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends ConsumerState<FolderListScreen> {
  @override
  void initState() {
    super.initState();
    // 삭제한 지 30일이 지난 메모는 앱을 켤 때 영구 삭제한다. (F1F-5)
    ref.read(notesRepositoryProvider).purgeExpired();
  }

  Future<void> _newFolder() async {
    final name = await showFolderNameDialog(context, ref);
    if (name != null) await ref.read(foldersRepositoryProvider).create(name);
  }

  Future<void> _folderMenu(Folder folder, Offset at) async {
    if (folder.isSystem) return;
    final choice = await showMenuAt<String>(context, at, [
      menuItem('rename', Icons.edit_outlined, '이름 변경'),
      menuItem('delete', Icons.delete_outline, '폴더 삭제', destructive: true),
    ]);
    if (!mounted) return;
    final repo = ref.read(foldersRepositoryProvider);
    if (choice == 'rename') {
      final name = await showFolderNameDialog(
        context,
        ref,
        initial: folder.name,
        exceptId: folder.id,
      );
      if (name != null) await repo.rename(folder.id, name);
    } else if (choice == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("'${folder.name}' 폴더를 삭제할까요?"),
          content: const Text('폴더 안의 메모는 최근 삭제된 항목으로 이동합니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              key: const Key('confirmDeleteFolder'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        ),
      );
      if (ok == true) await repo.delete(folder.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(foldersProvider).value ?? const <Folder>[];
    final counts = ref.watch(folderCountsProvider).value ?? const {};
    final main = folders.where((f) => f.id != SystemFolders.trash).toList();
    final trash = folders.where((f) => f.id == SystemFolders.trash).toList();

    Widget tile(Folder f) => _FolderTile(
      folder: f,
      count: counts[f.id] ?? 0,
      onMenu: (at) => _folderMenu(f, at),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('폴더'),
        centerTitle: false,
        titleTextStyle: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ...main.map(tile),
          if (trash.isNotEmpty) ...[
            const Divider(height: 24, indent: 16, endIndent: 16),
            ...trash.map(tile),
          ],
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        height: 56,
        child: Row(
          children: [
            IconButton(
              key: const Key('newFolderButton'),
              tooltip: '새로운 폴더',
              icon: const Icon(Icons.create_new_folder_outlined),
              onPressed: _newFolder,
            ),
            const Spacer(),
            IconButton(
              key: const Key('newNoteButton'),
              tooltip: '새로운 메모',
              icon: const Icon(Icons.edit_square),
              onPressed: () => openNewNote(context, ref, SystemFolders.notes),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.folder,
    required this.count,
    required this.onMenu,
  });

  final Folder folder;
  final int count;
  final void Function(Offset) onMenu;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (d) => onMenu(d.globalPosition),
      onSecondaryTapUp: (d) => onMenu(d.globalPosition),
      child: ListTile(
        key: Key('folder-${folder.id}'),
        leading: Icon(
          folderIcon(folder),
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(folder.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NoteListScreen(folderId: folder.id),
          ),
        ),
      ),
    );
  }
}
