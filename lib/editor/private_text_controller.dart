import 'package:material_ui/material_ui.dart';

import 'box_colors.dart';
import 'editor_history.dart';
import 'hidden_ranges.dart';

/// 프라이빗 드래그 박스와 되돌리기 기록을 다루는 텍스트 컨트롤러.
///
/// 사용자가 입력하거나 커서를 옮기면 [value] setter로 들어오므로,
/// 여기서 가린 범위 이동, 박스 안 커서 막기, 되돌리기 기록을 한 번에 처리한다.
class PrivateTextController extends TextEditingController {
  PrivateTextController({super.text, List<HiddenRange> hidden = const []})
    : _hidden = clampRanges(hidden, text?.length ?? 0);

  final EditorHistory _history = EditorHistory();

  List<HiddenRange> _hidden;

  /// `수정` 중인 어절. 커서가 이 어절을 벗어나면 다시 박스가 된다. (F4-2)
  HiddenRange? _editing;

  /// `보기`로 잠시 연 어절. 저장하지 않는다. (F4-4, F4-5)
  HiddenRange? _revealed;

  bool _internal = false;

  List<HiddenRange> get hidden => List.unmodifiable(_hidden);
  HiddenRange? get editingRange => _editing;
  HiddenRange? get revealedRange => _revealed;
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  /// 지금 박스로 그려지는 범위인지(수정 중·보기 중이면 아님).
  bool isBoxed(HiddenRange r) => r != _editing && r != _revealed;

  /// 커서 오프셋 [offset]에 걸친, 지금 박스로 보이는 범위.
  HiddenRange? boxAt(int offset) {
    for (final r in _hidden) {
      if (r.touches(offset) && isBoxed(r)) return r;
    }
    return null;
  }

  EditorSnapshot get _snapshot => EditorSnapshot(text, selection, _hidden);

  void _setInternal(TextEditingValue v) {
    _internal = true;
    try {
      super.value = v;
    } finally {
      _internal = false;
    }
  }

  @override
  set value(TextEditingValue newValue) {
    if (_internal) {
      super.value = newValue;
      return;
    }
    final old = super.value;
    if (newValue.text != old.text) {
      _onTextEdit(old, newValue);
    } else {
      _onSelectionChange(old, newValue);
    }
  }

  void _onTextEdit(TextEditingValue old, TextEditingValue next) {
    final cursor = next.selection.isValid && next.selection.isCollapsed
        ? next.selection.baseOffset
        : null;
    final edit = diffText(old.text, next.text, cursor: cursor);
    final editing = _editing;
    final inEditingWord =
        editing != null &&
        edit.start >= editing.start &&
        edit.oldEnd <= editing.end;

    _history.recordEdit(EditorSnapshot(old.text, old.selection, _hidden), edit);
    _hidden = applyEdit(_hidden, edit, hideInserted: inEditingWord);
    _revealed = null;

    if (inEditingWord) {
      // 나뉜 어절 중 커서가 있는 쪽을 계속 수정한다.
      _editing = _rangeTouching(cursor ?? edit.start + edit.inserted.length);
    } else {
      _editing = null;
    }
    _setInternal(next);
  }

  void _onSelectionChange(TextEditingValue old, TextEditingValue next) {
    var value = next;
    final sel = next.selection;
    // IME 동기화처럼 커서가 그대로인 값 갱신에서는 `보기`를 유지한다.
    if (sel != old.selection) _revealed = null;

    final editing = _editing;
    if (editing != null) {
      final stillInside =
          sel.isValid && sel.start >= editing.start && sel.end <= editing.end;
      if (!stillInside) _editing = null;
    }

    // 박스를 짧게 누르거나 방향키로 들어오면 박스 앞/뒤로 보낸다. (F4-6)
    if (sel.isValid && sel.isCollapsed && next.composing.isCollapsed) {
      final off = sel.baseOffset;
      final box = _hidden
          .where((r) => r.strictlyContains(off) && isBoxed(r))
          .firstOrNull;
      if (box != null) {
        final prev = old.selection;
        int target;
        if (prev.isValid &&
            prev.isCollapsed &&
            (off - prev.baseOffset).abs() == 1) {
          // 방향키 한 칸: 이동 방향으로 박스를 건너뛴다.
          target = prev.baseOffset <= box.start ? box.end : box.start;
        } else {
          target = (off - box.start) <= (box.end - off) ? box.start : box.end;
        }
        value = next.copyWith(
          selection: TextSelection.collapsed(offset: target),
        );
      }
    }
    _setInternal(value);
  }

  HiddenRange? _rangeTouching(int offset) {
    for (final r in _hidden) {
      if (r.touches(offset)) return r;
    }
    return null;
  }

  /// `프라이빗`: 선택에 걸친 어절을 가린다. (F3-1)
  void hideSelection() {
    final sel = selection;
    if (!sel.isValid || sel.isCollapsed) return;
    final next = hideRange(text, _hidden, sel.start, sel.end);
    _applyAction(next, sel);
  }

  /// `해제`: 선택에 걸친 어절의 박스를 푼다. (F3-3)
  void unhideSelection() {
    final sel = selection;
    if (!sel.isValid || sel.isCollapsed) return;
    final next = unhideRange(text, _hidden, sel.start, sel.end);
    _applyAction(next, sel);
  }

  bool get selectionCanHide {
    final sel = selection;
    return sel.isValid &&
        !sel.isCollapsed &&
        canHide(text, _hidden, sel.start, sel.end);
  }

  bool get selectionCanUnhide {
    final sel = selection;
    return sel.isValid &&
        !sel.isCollapsed &&
        canUnhide(text, _hidden, sel.start, sel.end);
  }

  void _applyAction(List<HiddenRange> next, TextSelection sel) {
    _history.recordAction(_snapshot);
    _hidden = next;
    _editing = null;
    _revealed = null;
    // 선택을 끝으로 접는다. 끝이 박스 안이면 박스 뒤로.
    var end = sel.end;
    for (final r in _hidden) {
      if (r.strictlyContains(end)) end = r.end;
    }
    _setInternal(
      value.copyWith(
        selection: TextSelection.collapsed(offset: end),
        composing: TextRange.empty,
      ),
    );
  }

  /// `수정`: 박스 어절을 현재 어절로 만들어 편집한다. (F4-2)
  void startEditing(HiddenRange box) {
    _history.breakGroup();
    _editing = box;
    _revealed = null;
    _setInternal(
      value.copyWith(
        selection: TextSelection.collapsed(offset: box.end),
        composing: TextRange.empty,
      ),
    );
  }

  /// `보기`: 박스 어절을 잠시 연다. (F4-4)
  void reveal(HiddenRange box) {
    _editing = null;
    _revealed = box;
    _setInternal(
      value.copyWith(
        selection: TextSelection.collapsed(offset: box.end),
        composing: TextRange.empty,
      ),
    );
  }

  /// 화면 아무 곳이나 누르면 `보기`로 연 박스를 다시 가린다. (F4-4)
  void dismissReveal() {
    if (_revealed == null) return;
    _revealed = null;
    notifyListeners();
  }

  void undo() => _restore(_history.undo(_snapshot));

  void redo() => _restore(_history.redo(_snapshot));

  void _restore(EditorSnapshot? s) {
    if (s == null) return;
    _hidden = s.hidden;
    _editing = null;
    _revealed = null;
    final selection = s.selection.isValid
        ? s.selection
        : TextSelection.collapsed(offset: s.text.length);
    _setInternal(TextEditingValue(text: s.text, selection: selection));
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final boxColor = boxColorOf(context);
    return TextSpan(
      style: style,
      children: buildMaskedSpans(
        text: text,
        boxes: _hidden.where(isBoxed).toList(),
        boxColor: boxColor,
        composing: withComposing && value.isComposingRangeValid
            ? value.composing
            : null,
      ),
    );
  }
}

/// [boxes] 범위는 글자를 투명하게 하고 회색 배경을 칠해 박스로 그린다.
/// 글자는 그대로 있으므로 박스 길이 = 글자 길이다.
List<InlineSpan> buildMaskedSpans({
  required String text,
  required List<HiddenRange> boxes,
  required Color boxColor,
  TextRange? composing,
}) {
  if (text.isEmpty) return const [];
  final cuts = <int>{0, text.length};
  for (final b in boxes) {
    cuts
      ..add(b.start.clamp(0, text.length))
      ..add(b.end.clamp(0, text.length));
  }
  if (composing != null) {
    cuts
      ..add(composing.start)
      ..add(composing.end);
  }
  final points = cuts.toList()..sort();
  final boxStyle = TextStyle(
    color: const Color(0x00000000),
    backgroundColor: boxColor,
  );
  const composingStyle = TextStyle(decoration: TextDecoration.underline);

  final spans = <InlineSpan>[];
  for (var i = 0; i < points.length - 1; i++) {
    final a = points[i];
    final b = points[i + 1];
    if (a >= b) continue;
    final boxed = boxes.any((r) => r.covers(a));
    final inComposing =
        composing != null && a >= composing.start && b <= composing.end;
    TextStyle? style;
    if (boxed) style = boxStyle;
    if (inComposing) style = (style ?? const TextStyle()).merge(composingStyle);
    spans.add(TextSpan(text: text.substring(a, b), style: style));
  }
  return spans;
}
