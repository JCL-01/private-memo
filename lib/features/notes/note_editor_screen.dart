import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/note.dart';
import '../../data/notes_repository.dart';
import '../../data/providers.dart';
import '../../editor/hidden_ranges.dart';
import '../../editor/private_editor.dart';
import '../../editor/private_text_controller.dart';

/// 메모 편집 화면.
///
/// 입력이 멈추면 본문과 가린 범위를 자동 저장하고,
/// 화면을 나갈 때 내용이 비어 있으면 메모를 지운다.
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  static const _saveDelay = Duration(milliseconds: 400);

  PrivateTextController? _controller;
  final _focusNode = FocusNode();
  late final NotesRepository _repo;
  Timer? _saveTimer;
  bool _deleted = false;
  String _savedContent = '';
  String _savedHidden = '[]';

  @override
  void initState() {
    super.initState();
    _repo = ref.read(notesRepositoryProvider);
    _load();
  }

  Future<void> _load() async {
    final note = await _repo.getById(widget.noteId);
    if (!mounted) return;
    _savedContent = note?.content ?? '';
    final hidden = note?.hidden ?? const <HiddenRange>[];
    final controller = PrivateTextController(
      text: _savedContent,
      hidden: hidden,
    );
    _savedHidden = encodeRanges(controller.hidden);
    controller.addListener(_scheduleSave);
    setState(() => _controller = controller);
    if (_savedContent.isEmpty) _focusNode.requestFocus();
  }

  bool get _dirty {
    final c = _controller;
    if (c == null) return false;
    return c.text != _savedContent || encodeRanges(c.hidden) != _savedHidden;
  }

  void _scheduleSave() {
    if (!_dirty) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, _save);
  }

  Future<void> _save() async {
    final c = _controller;
    if (_deleted || c == null || !_dirty) return;
    _savedContent = c.text;
    _savedHidden = encodeRanges(c.hidden);
    await _repo.updateContent(
      widget.noteId,
      _savedContent,
      hiddenRanges: _savedHidden,
    );
  }

  Future<void> _delete() async {
    _deleted = true;
    _saveTimer?.cancel();
    await _repo.delete(widget.noteId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    final c = _controller;
    if (!_deleted && c != null) {
      // 나갈 때: 비어 있으면 삭제, 아니면 마지막 내용 저장
      if (c.text.trim().isEmpty) {
        _repo.delete(widget.noteId);
      } else if (_dirty) {
        _repo.updateContent(
          widget.noteId,
          c.text,
          hiddenRanges: encodeRanges(c.hidden),
        );
      }
    }
    c?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (c != null)
            ListenableBuilder(
              listenable: c,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const Key('undoButton'),
                    tooltip: '되돌리기 (Ctrl+Z)',
                    icon: const Icon(Icons.undo),
                    onPressed: c.canUndo ? c.undo : null,
                  ),
                  IconButton(
                    key: const Key('redoButton'),
                    tooltip: '다시 실행 (Ctrl+Y)',
                    icon: const Icon(Icons.redo),
                    onPressed: c.canRedo ? c.redo : null,
                  ),
                ],
              ),
            ),
          IconButton(
            key: const Key('deleteNoteButton'),
            tooltip: '메모 삭제',
            icon: const Icon(Icons.delete_outline),
            onPressed: c != null ? _delete : null,
          ),
        ],
      ),
      body: c == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PrivateEditor(
                controller: c,
                focusNode: _focusNode,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(fontSize: 17, height: 1.5),
              ),
            ),
    );
  }
}
