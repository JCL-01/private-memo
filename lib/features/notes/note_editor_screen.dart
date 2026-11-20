import 'dart:async';

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/note.dart';
import '../../data/database.dart';
import '../../data/notes_repository.dart';
import '../../data/providers.dart';
import '../../editor/edit_navigator_bar.dart';
import '../../editor/hidden_ranges.dart';
import '../../editor/private_editor.dart';
import '../../editor/private_text_controller.dart';
import '../../editor/private_view.dart';
import '../../organize/block_box.dart';
import '../../organize/note_blocks.dart';
import '../../organize/organizer.dart';
import '../folders/folder_dialogs.dart';

/// 정리하기·박스 삭제·잘라내기 전후의 문서 상태(되돌리기용). (F8-2e)
class _DocState {
  const _DocState(this.blocks, this.text, this.hidden);

  final List<NoteBlock> blocks;
  final String text;
  final List<HiddenRange> hidden;
}

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

  /// 메모가 담긴 폴더. `최근 삭제된 항목`이면 읽기 전용. (F1F-6)
  String _folderId = SystemFolders.notes;
  bool get _inTrash => _folderId == SystemFolders.trash;

  /// 정리 기능의 원본·정리본 박스. 본문 위에 놓인다. (F8-2)
  List<NoteBlock> _blocks = const [];
  final _docUndo = <_DocState>[];
  final _docRedo = <_DocState>[];
  final _docScroll = ScrollController();
  final _blockKeys = <int, GlobalKey>{};
  bool _organizing = false;

  bool get _isQuick => _folderId == SystemFolders.quick;

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
    _folderId = note?.folderId ?? SystemFolders.notes;
    _blocks = decodeBlocks(note?.blocks ?? '[]');
    final hidden = note?.hidden ?? const <HiddenRange>[];
    final controller = PrivateTextController(
      text: _savedContent,
      hidden: hidden,
      privateMode: note?.privateMode ?? false,
    );
    _savedHidden = encodeRanges(controller.hidden);
    controller.addListener(_scheduleSave);

    setState(() => _controller = controller);
    if (_savedContent.isEmpty && _blocks.isEmpty && !_inTrash) {
      _focusNode.requestFocus();
    }
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

  /// 삭제: `최근 삭제된 항목`으로 옮긴다. 빈 메모는 바로 없앤다. (F1F-5, F1F-7)
  Future<void> _delete() async {
    _saveTimer?.cancel();
    final c = _controller;
    if (c != null && c.text.trim().isEmpty && _blocks.isEmpty) {
      _deleted = true;
      await _repo.delete(widget.noteId);
    } else {
      await _save();
      await _repo.moveToTrash(widget.noteId);
      _deleted = true;
    }
    if (mounted) Navigator.of(context).pop();
  }

  // ───────────────────────── 정리 (F8-2) ─────────────────────────

  _DocState _docState() {
    final c = _controller!;
    return _DocState(List.of(_blocks), c.text, c.hidden);
  }

  /// 문서 단위 변경(정리하기, 박스 삭제·잘라내기)을 되돌리기 기록에 남기고 적용한다.
  Future<void> _applyDoc(_DocState next, {bool record = true}) async {
    final c = _controller!;
    if (record) {
      _docUndo.add(_docState());
      _docRedo.clear();
    }
    setState(() => _blocks = next.blocks);
    if (c.text != next.text ||
        encodeRanges(c.hidden) != encodeRanges(next.hidden)) {
      c.resetDocument(next.text, next.hidden);
    }
    _saveTimer?.cancel();
    _savedContent = c.text;
    _savedHidden = encodeRanges(c.hidden);
    await _repo.updateContent(
      widget.noteId,
      _savedContent,
      hiddenRanges: _savedHidden,
    );
    await _repo.updateBlocks(widget.noteId, encodeBlocks(_blocks));
  }

  bool get _canUndo => (_controller?.canUndo ?? false) || _docUndo.isNotEmpty;
  bool get _canRedo => (_controller?.canRedo ?? false) || _docRedo.isNotEmpty;

  /// 되돌리기: 글자 편집이 있으면 그것부터, 없으면 정리하기·박스 변경을 되돌린다.
  void _undo() {
    final c = _controller!;
    if (c.canUndo) {
      c.undo();
    } else if (_docUndo.isNotEmpty) {
      _docRedo.add(_docState());
      _applyDoc(_docUndo.removeLast(), record: false);
    }
    setState(() {});
  }

  void _redo() {
    final c = _controller!;
    if (c.canRedo) {
      c.redo();
    } else if (_docRedo.isNotEmpty) {
      _docUndo.add(_docState());
      _applyDoc(_docRedo.removeLast(), record: false);
    }
    setState(() {});
  }

  /// `정리`: 지금 쓴 글을 `원본` 박스에 담고, 바로 아래 `정리본` 박스를 만든다. (F8-2a)
  Future<void> _organize() async {
    final c = _controller;
    if (c == null || c.text.trim().isEmpty || _organizing) return;
    setState(() => _organizing = true);
    final result = await organizeMemo(c.text);
    if (!mounted) return;
    final original = NoteBlock(
      kind: BlockKind.original,
      text: c.text,
      hidden: c.hidden,
    );
    final organized = NoteBlock(
      kind: BlockKind.organized,
      text: result.toText(),
      // 원본에 가린 내용이 있으면 정리본 전체를 가린다. (F8-2f)
      isPrivate: c.hidden.isNotEmpty,
    );
    await _applyDoc(_DocState([..._blocks, original, organized], '', const []));
    if (!mounted) return;
    setState(() => _organizing = false);
    // 정리본으로 내려가 초점을 맞춘다. (F8-2c)
    final key = _blockKeys[_blocks.length - 1];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          alignment: 0.05,
        );
      }
    });
  }

  Future<void> _deleteBlock(int i) => _applyDoc(
    _DocState(
      [..._blocks]..removeAt(i),
      _controller!.text,
      _controller!.hidden,
    ),
  );

  /// `선택`: 원본·정리본 중 하나만 남긴다. 짝이 되는 다른 박스는 지우고,
  /// 선택한 내용은 박스에서 빠져나와 본문이 된다. (F8-2b)
  Future<void> _selectBlock(int i) async {
    final c = _controller!;
    final chosen = _blocks[i];
    // 정리하기 한 번에 [원본, 정리본] 한 쌍이 생긴다. 고른 박스의 짝을 찾는다.
    final pairStart = chosen.kind == BlockKind.original ? i : i - 1;
    final hasPair =
        pairStart >= 0 &&
        pairStart + 1 < _blocks.length &&
        _blocks[pairStart].kind == BlockKind.original &&
        _blocks[pairStart + 1].kind == BlockKind.organized;
    final remove = hasPair ? {pairStart, pairStart + 1} : {i};
    final rest = [
      for (var k = 0; k < _blocks.length; k++)
        if (!remove.contains(k)) _blocks[k],
    ];

    // 고른 내용을 본문 앞에 놓는다. 가린 범위도 함께 옮긴다.
    // 가려져 있던 정리본은 본문에서도 모든 어절을 가린 채로 둔다(프라이빗 드래그로 해제 가능).
    final chosenHidden = chosen.isPrivate
        ? allWords(chosen.text)
        : chosen.hidden;
    final rest0 = c.text;
    final sep = rest0.trim().isEmpty ? '' : '\n';
    final text = rest0.trim().isEmpty
        ? chosen.text
        : '${chosen.text}$sep$rest0';
    final shift = chosen.text.length + sep.length;
    final hidden = [
      ...chosenHidden,
      if (rest0.trim().isNotEmpty)
        for (final r in c.hidden) HiddenRange(r.start + shift, r.end + shift),
    ];
    await _applyDoc(_DocState(rest, text, hidden));
  }

  Future<void> _copyBlock(int i) async {
    await Clipboard.setData(ClipboardData(text: _blocks[i].text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${_blocks[i].label}을 복사했습니다.')));
  }

  Future<void> _cutBlock(int i) async {
    await Clipboard.setData(ClipboardData(text: _blocks[i].text));
    await _deleteBlock(i);
  }

  /// 정리본 `해제` / `가리기`. (F8-2f)
  Future<void> _toggleReveal(int i) async {
    final next = [..._blocks];
    next[i] = next[i].copyWith(revealed: !next[i].revealed);
    setState(() => _blocks = next);
    await _repo.updateBlocks(widget.noteId, encodeBlocks(_blocks));
  }

  Widget _blockList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _blocks.length; i++)
          BlockBox(
            key: _blockKeys.putIfAbsent(i, GlobalKey.new),
            block: _blocks[i],
            onSelect: () => _selectBlock(i),
            onCut: () => _cutBlock(i),
            onCopy: () => _copyBlock(i),
            onToggleReveal: _blocks[i].isPrivate
                ? () => _toggleReveal(i)
                : null,
          ),
      ],
    );
  }

  /// 폴더로 이동. (F1F-4)
  Future<void> _move() async {
    final target = await showMoveFolderSheet(
      context,
      ref,
      currentFolderId: _folderId,
    );
    if (target == null) return;
    await _save();
    await _repo.moveTo(widget.noteId, target);
    if (mounted) setState(() => _folderId = target);
  }

  /// 최근 삭제된 항목의 메모를 복구한다. (F1F-6)
  Future<void> _restore() async {
    await _repo.restore(widget.noteId);
    final note = await _repo.getById(widget.noteId);
    if (mounted) setState(() => _folderId = note?.folderId ?? _folderId);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    final c = _controller;
    if (!_deleted && c != null && !_inTrash) {
      // 나갈 때: 비어 있으면 삭제, 아니면 마지막 내용 저장
      if (c.text.trim().isEmpty && _blocks.isEmpty) {
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
    _docScroll.dispose();
    super.dispose();
  }

  Widget _editor(PrivateTextController c) => PrivateEditor(
    controller: c,
    focusNode: _focusNode,
    readOnly: _inTrash,
    style: Theme.of(context).textTheme.bodyLarge
        ?.copyWith(fontSize: 17, height: 1.5),
  );

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      appBar: AppBar(
        actions: _inTrash
            ? [
                TextButton(
                  key: const Key('restoreNoteButton'),
                  onPressed: _restore,
                  child: const Text('복구'),
                ),
              ]
            : [
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
                          onPressed: _canUndo ? _undo : null,
                        ),
                        IconButton(
                          key: const Key('redoButton'),
                          tooltip: '다시 실행 (Ctrl+Y)',
                          icon: const Icon(Icons.redo),
                          onPressed: _canRedo ? _redo : null,
                        ),
                      ],
                    ),
                  ),
                // 빠른 메모 폴더의 메모에만 `정리` 버튼. (F8-2)
                if (c != null && _isQuick)
                  ListenableBuilder(
                    listenable: c,
                    builder: (context, _) => TextButton(
                      key: const Key('organizeButton'),
                      onPressed: c.text.trim().isEmpty || _organizing
                          ? null
                          : _organize,
                      child: Text(_organizing ? '정리 중…' : '정리'),
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
                  key: const Key('moveNoteButton'),
                  tooltip: '폴더로 이동',
                  icon: const Icon(Icons.drive_file_move_outline),
                  onPressed: c != null ? _move : null,
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
                if (_inTrash)
                  Material(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text('최근 삭제된 항목의 메모입니다. 편집하려면 복구하세요.'),
                    ),
                  ),
                Expanded(
                  child: _blocks.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _editor(c),
                        )
                      // 박스가 있으면 박스들 아래에 이어 쓰는 본문을 둔다.
                      : LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                                controller: _docScroll,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _blockList(),
                                    SizedBox(
                                      height: constraints.maxHeight * 0.6,
                                      child: _editor(c),
                                    ),
                                  ],
                                ),
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
