import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/database.dart';
import '../../data/providers.dart';

/// 폴더 이름 입력 창(새 폴더, 이름 변경). 확인하면 이름을 돌려준다.
Future<String?> showFolderNameDialog(
  BuildContext context,
  WidgetRef ref, {
  String? initial,
  String? exceptId,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        _FolderNameDialog(initial: initial, exceptId: exceptId, ref: ref),
  );
}

class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog({this.initial, this.exceptId, required this.ref});

  final String? initial;
  final String? exceptId;
  final WidgetRef ref;

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final _controller = TextEditingController(text: widget.initial ?? '');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = await widget.ref
        .read(foldersRepositoryProvider)
        .validateName(_controller.text, exceptId: widget.exceptId);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? '새로운 폴더' : '폴더 이름 변경'),
      content: TextField(
        key: const Key('folderNameField'),
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: '이름', errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          key: const Key('folderNameSave'),
          onPressed: _submit,
          child: const Text('저장'),
        ),
      ],
    );
  }
}

/// 메모를 옮길 폴더 고르기. (F1F-4)
/// `최근 삭제된 항목`과 지금 폴더는 목록에서 뺀다.
Future<String?> showMoveFolderSheet(
  BuildContext context,
  WidgetRef ref, {
  required String currentFolderId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final folders = ref.watch(foldersProvider).value ?? const <Folder>[];
        final targets = folders
            .where(
              (f) => f.id != SystemFolders.trash && f.id != currentFolderId,
            )
            .toList();
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  '폴더로 이동',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              for (final f in targets)
                ListTile(
                  key: Key('moveTo-${f.id}'),
                  leading: Icon(folderIcon(f)),
                  title: Text(f.name),
                  onTap: () => Navigator.of(context).pop(f.id),
                ),
            ],
          ),
        );
      },
    ),
  );
}

IconData folderIcon(Folder f) => switch (f.id) {
  SystemFolders.quick => Icons.bolt_outlined,
  SystemFolders.trash => Icons.delete_outline,
  _ => Icons.folder_outlined,
};

/// 길게 누르기·우클릭 위치에 메뉴를 띄운다.
Future<T?> showMenuAt<T>(
  BuildContext context,
  Offset position,
  List<PopupMenuEntry<T>> items,
) {
  return showMenu<T>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx,
      position.dy,
    ),
    items: items,
  );
}

PopupMenuItem<String> menuItem(
  String value,
  IconData icon,
  String label, {
  bool destructive = false,
}) {
  final color = destructive ? Colors.red : null;
  return PopupMenuItem(
    value: value,
    child: ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
    ),
  );
}
