import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show RenderEditable;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'box_colors.dart';
import 'box_painter.dart';
import 'private_text_controller.dart';

class UndoEditIntent extends Intent {
  const UndoEditIntent();
}

class RedoEditIntent extends Intent {
  const RedoEditIntent();
}

class ExitModesIntent extends Intent {
  const ExitModesIntent();
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

  final _fieldKey = GlobalKey();
  final _paintKey = GlobalKey();
  final _scroll = ScrollController();
  EditableTextState? _editable;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// TextField 안의 EditableTextState(박스 위치 계산용).
  RenderEditable? _findEditable() {
    final cached = _editable;
    if (cached != null && cached.mounted) return cached.renderEditable;
    EditableTextState? found;
    void visit(Element e) {
      if (found != null) return;
      if (e is StatefulElement && e.state is EditableTextState) {
        found = e.state as EditableTextState;
        return;
      }
      e.visitChildElements(visit);
    }

    _fieldKey.currentContext?.visitChildElements(visit);
    _editable = found;
    return found?.renderEditable;
  }

  static const _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.keyZ, control: true): UndoEditIntent(),
    SingleActivator(LogicalKeyboardKey.keyY, control: true): RedoEditIntent(),
    SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
        RedoEditIntent(),
    SingleActivator(LogicalKeyboardKey.keyZ, meta: true): UndoEditIntent(),
    SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
        RedoEditIntent(),
    // Esc: 수정·보기에서 빠져나오기 (F4-10)
    SingleActivator(LogicalKeyboardKey.escape): ExitModesIntent(),
  };

  void _onPointerDown(PointerDownEvent e) {
    _pointerDownAt = e.position;
    _pointerMoved = false;
    // 우클릭으로 커서가 옮겨져도 프라이빗 모드의 현재 어절은 그대로 둔다.
    if (e.buttons & kSecondaryButton != 0) {
      _c.holdAnchor();
    } else {
      _c.releaseAnchor();
    }
  }

  /// 손가락·마우스를 떼면 `보기`로 연 박스를 다시 가린다.
  /// 누르고 있는 동안에는 가리지 않는다. (F4-4)
  void _onPointerUp(PointerUpEvent e) {
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
          onPressed: () => run(() => _c.startEditing(boxes)),
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
          ExitModesIntent: CallbackAction<ExitModesIntent>(
            onInvoke: (_) {
              _c.exitModes();
              return null;
            },
          ),
        },
        child: Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          child: Stack(
            children: [
              // 박스는 글자 뒤에 같은 높이로 따로 그린다.
              Positioned.fill(
                child: CustomPaint(
                  key: _paintKey,
                  painter: HiddenBoxPainter(
                    controller: _c,
                    findEditable: _findEditable,
                    selfBox: () =>
                        _paintKey.currentContext?.findRenderObject()
                            as RenderBox?,
                    boxColor: boxColorOf(context),
                    boxHeight: (widget.style?.fontSize ?? 16) * 0.95,
                    underlineColor: Theme.of(context).colorScheme.error,
                    repaint: _scroll,
                  ),
                ),
              ),
              KeyedSubtree(key: _fieldKey, child: _buildField()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField() {
    return TextField(
      scrollController: _scroll,
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
    );
  }
}
