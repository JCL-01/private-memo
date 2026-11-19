import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'private_text_controller.dart';

class UndoEditIntent extends Intent {
  const UndoEditIntent();
}

class RedoEditIntent extends Intent {
  const RedoEditIntent();
}

/// 프라이빗 드래그와 박스 동작을 지원하는 메모 에디터.
///
/// - 선택 후 메뉴: 기본 메뉴 + `프라이빗` / `해제` (F3)
/// - 박스를 길게 누르기·우클릭: `수정` / `보기` (F4-1)
/// - Ctrl+Z 되돌리기, Ctrl+Y·Ctrl+Shift+Z 다시 실행 (F5-2)
class PrivateEditor extends StatefulWidget {
  const PrivateEditor({
    super.key,
    required this.controller,
    this.focusNode,
    this.style,
  });

  final PrivateTextController controller;
  final FocusNode? focusNode;
  final TextStyle? style;

  @override
  State<PrivateEditor> createState() => _PrivateEditorState();
}

class _PrivateEditorState extends State<PrivateEditor> {
  Offset? _pointerDownAt;
  bool _pointerMoved = false;

  PrivateTextController get _c => widget.controller;

  static const _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.keyZ, control: true): UndoEditIntent(),
    SingleActivator(LogicalKeyboardKey.keyY, control: true): RedoEditIntent(),
    SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
        RedoEditIntent(),
    SingleActivator(LogicalKeyboardKey.keyZ, meta: true): UndoEditIntent(),
    SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
        RedoEditIntent(),
  };

  void _onPointerDown(PointerDownEvent e) {
    _pointerDownAt = e.position;
    _pointerMoved = false;
    // 화면을 누르면 `보기`로 연 박스는 다시 가린다. (F4-4)
    _c.dismissReveal();
  }

  void _onPointerMove(PointerMoveEvent e) {
    final start = _pointerDownAt;
    if (start != null && (e.position - start).distance > kTouchSlop) {
      _pointerMoved = true;
    }
  }

  /// 길게 누르기·우클릭한 지점의 본문 오프셋.
  int? _pressedOffset(EditableTextState state) {
    final at = _pointerDownAt;
    if (at == null || _pointerMoved) return null;
    return state.renderEditable.getPositionForPoint(at).offset;
  }

  Widget _buildContextMenu(BuildContext context, EditableTextState state) {
    final boxes = _c.boxesForMenu(pressedOffset: _pressedOffset(state));
    final private = _c.privateMode;

    void run(VoidCallback action) {
      state.hideToolbar();
      action();
    }

    final items = <ContextMenuButtonItem>[
      // 박스가 걸쳐 있으면: 수정 · 보기 · 해제(일반 모드만) (F4-1)
      if (boxes.isNotEmpty) ...[
        ContextMenuButtonItem(
          label: '수정',
          onPressed: () => run(() => _c.startEditing(boxes.first)),
        ),
        ContextMenuButtonItem(
          label: '보기',
          onPressed: () => run(() => _c.reveal(boxes)),
        ),
        if (!private)
          ContextMenuButtonItem(
            label: '해제',
            onPressed: () => run(() => _c.unhideBoxes(boxes)),
          ),
      ],
      // 가리지 않은 어절이 선택에 있으면: 프라이빗(일반 모드만) (F3-1)
      if (!private && _c.selectionCanHide)
        ContextMenuButtonItem(
          label: '프라이빗',
          onPressed: () => run(_c.hideSelection),
        ),
      // 복사·잘라내기·붙여넣기 등 기본 메뉴 (F3-6)
      ...state.contextMenuButtonItems,
    ];
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: {
          UndoEditIntent: CallbackAction<UndoEditIntent>(
            onInvoke: (_) {
              _c.undo();
              return null;
            },
          ),
          RedoEditIntent: CallbackAction<RedoEditIntent>(
            onInvoke: (_) {
              _c.redo();
              return null;
            },
          ),
        },
        child: Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          child: TextField(
            key: const Key('noteEditor'),
            controller: _c,
            focusNode: widget.focusNode,
            maxLines: null,
            expands: true,
            keyboardType: TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
            style: widget.style,
            contextMenuBuilder: _buildContextMenu,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '메모를 입력하세요',
            ),
          ),
        ),
      ),
    );
  }
}
