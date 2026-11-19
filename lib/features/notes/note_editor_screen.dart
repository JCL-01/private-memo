import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/note.dart';
import '../../data/notes_repository.dart';
import '../../data/providers.dart';
import '../../editor/edit_navigator_bar.dart';
import '../../editor/hidden_ranges.dart';
import '../../editor/private_editor.dart';
import '../../editor/private_text_controller.dart';
import '../../spell/spell_check_runner.dart';
import '../../spell/spell_providers.dart';

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
  SpellCheckRunner? _spell;
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
      privateMode: note?.privateMode ?? false,
    );
    _savedHidden = encodeRanges(controller.hidden);
    controller.addListener(_scheduleSave);
    // 맞춤법 검사: 입력이 멈추면 바뀐 어절만 검사해 밑줄을 긋는다. (F6)
    _spell = SpellCheckRunner(
      controller,
      checker: ref.read(spellCheckerProvider).value,
    );
    ref.listenManual(spellCheckerProvider, (_, next) {
      final checker = next.value;
      if (checker != null) _spell?.checker = checker;
    });
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

  /// `프라이빗` / `해제` 버튼. (F2-8)
  void _togglePrivateMode() {
    final c = _controller;
    if (c == null) return;
    c.privateMode = !c.privateMode;
    _repo.setPrivateMode(widget.noteId, c.privateMode);
    _focusNode.requestFocus();
  }

  void _jump(void Function() move) {
    _focusNode.requestFocus();
    move();
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
    _spell?.dispose();
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
          if (c != null)
            ListenableBuilder(
              listenable: c,
              builder: (context, _) => TextButton(
                key: const Key('privateModeToggle'),
                onPressed: _togglePrivateMode,
                child: Text(c.privateMode ? '해제' : '프라이빗'),
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
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: PrivateEditor(
                      controller: c,
                      focusNode: _focusNode,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(fontSize: 17, height: 1.5),
                    ),
                  ),
                ),
                EditNavigatorBar(controller: c),
                _PrivateModeBar(
                  controller: c,
                  onRecent: () => _jump(c.jumpToRecent),
                  onLast: () => _jump(c.jumpToLast),
                  onPrev: () => _jump(() => c.moveCurrentWord(-1)),
                  onNext: () => _jump(() => c.moveCurrentWord(1)),
                ),
              ],
            ),
    );
  }
}

/// 프라이빗 모드일 때만 보이는 이동 버튼: `최근`, `마지막`. (F2-6, F2-7)
class _PrivateModeBar extends StatelessWidget {
  const _PrivateModeBar({
    required this.controller,
    required this.onRecent,
    required this.onLast,
    required this.onPrev,
    required this.onNext,
  });

  final PrivateTextController controller;
  final VoidCallback onRecent;
  final VoidCallback onLast;

  /// 현재 어절을 이전·다음 어절로 옮기는 화살표. (F2-11)
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.privateMode) return const SizedBox.shrink();
        return Material(
          key: const Key('privateModeBar'),
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(
                    Icons.visibility_off_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '프라이빗 모드',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    key: const Key('jumpRecentButton'),
                    onPressed: onRecent,
                    child: const Text('최근'),
                  ),
                  TextButton(
                    key: const Key('jumpLastButton'),
                    onPressed: onLast,
                    child: const Text('마지막'),
                  ),
                  IconButton(
                    key: const Key('prevWordButton'),
                    tooltip: '이전 어절',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: controller.canMoveCurrentWordBack
                        ? onPrev
                        : null,
                  ),
                  IconButton(
                    key: const Key('nextWordButton'),
                    tooltip: '다음 어절',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: controller.canMoveCurrentWordForward
                        ? onNext
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
