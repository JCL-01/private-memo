import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'hidden_ranges.dart';
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

  /// 길게 누르기·우클릭한 지점의 박스.
  HiddenRange? _pressedBox(EditableTextState state) {
    final at = _pointerDownAt;
    if (at == null || _pointerMoved) return null;
    final offset = state.renderEditable.getPositionForPoint(at).offset;
    final box = _c.boxAt(offset);
    if (box == null) return null;
    final sel = state.textEditingValue.selection;
    final selectionIsOnBox =
        !sel.isValid ||
        sel.isCollapsed ||
        (sel.start >= box.start && sel.end <= box.end);
    return selectionIsOnBox ? box : null;
  }

  Widget _buildContextMenu(BuildContext context, EditableTextState state) {
    final box = _pressedBox(state);
    final List<ContextMenuButtonItem> items;
    if (box != null) {
      items = [
        ContextMenuButtonItem(
          label: '수정',
          onPressed: () {
            state.hideToolbar();
            _c.startEditing(box);
          },
        ),
        ContextMenuButtonItem(
          label: '보기',
          onPressed: () {
            state.hideToolbar();
            _c.reveal(box);
          },
        ),
      ];
    } else {
      items = [
        ...state.contextMenuButtonItems,
        if (_c.selectionCanHide)
          ContextMenuButtonItem(
            label: '프라이빗',
            onPressed: () {
              state.hideToolbar();
              _c.hideSelection();
            },
          ),
        if (_c.selectionCanUnhide)
          ContextMenuButtonItem(
            label: '해제',
            onPressed: () {
              state.hideToolbar();
              _c.unhideSelection();
            },
          ),
      ];
    }
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
