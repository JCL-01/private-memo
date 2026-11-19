import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/notes_repository.dart';
import '../../data/providers.dart';

/// 메모 편집 화면.
///
/// 입력이 멈추면 자동 저장하고, 화면을 나갈 때 내용이 비어 있으면 메모를 지운다.
/// (프라이빗 모드/프라이빗 드래그는 이후 단계에서 이 화면의 에디터를 교체해 추가한다.)
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  static const _saveDelay = Duration(milliseconds: 400);

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final NotesRepository _repo;
  Timer? _saveTimer;
  bool _loaded = false;
  bool _deleted = false;
  String _savedContent = '';

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
    _controller.text = _savedContent;
    _controller.addListener(_scheduleSave);
    setState(() => _loaded = true);
    if (_savedContent.isEmpty) _focusNode.requestFocus();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, _save);
  }

  Future<void> _save() async {
    final text = _controller.text;
    if (_deleted || text == _savedContent) return;
    _savedContent = text;
    await _repo.updateContent(widget.noteId, text);
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
    if (!_deleted && _loaded) {
      // 나갈 때: 비어 있으면 삭제, 아니면 마지막 내용 저장
      if (_controller.text.trim().isEmpty) {
        _repo.delete(widget.noteId);
      } else if (_controller.text != _savedContent) {
        _repo.updateContent(widget.noteId, _controller.text);
      }
    }
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            key: const Key('deleteNoteButton'),
            tooltip: '메모 삭제',
            icon: const Icon(Icons.delete_outline),
            onPressed: _loaded ? _delete : null,
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const Key('noteEditor'),
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(fontSize: 17, height: 1.5),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '메모를 입력하세요',
                ),
              ),
            ),
    );
  }
}
