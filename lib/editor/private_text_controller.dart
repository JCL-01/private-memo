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

  /// `보기`로 잠시 연 어절들. 저장하지 않는다. (F4-4, F4-5)
  Set<HiddenRange> _revealed = {};

  /// 프라이빗 모드 여부. 켜져 있으면 박스 메뉴에 `해제`·`프라이빗`이 없다. (F2)
  bool privateMode = false;

  bool _internal = false;

  List<HiddenRange> get hidden => List.unmodifiable(_hidden);
  HiddenRange? get editingRange => _editing;
  Set<HiddenRange> get revealedRanges => Set.unmodifiable(_revealed);

  /// 수정 모드 여부. 켜져 있으면 이전/다음/닫기 바를 보여 준다. (F4-2)
  bool get isEditingBox => _editing != null;

  /// 수정 중인 박스가 문서의 박스 중 몇 번째인지(0부터). 수정 중이 아니면 -1.
  int get editingIndex => _editing == null ? -1 : _hidden.indexOf(_editing!);

  int get boxCount => _hidden.length;
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  /// 지금 박스로 그려지는 범위인지(수정 중·보기 중이면 아님).
  bool isBoxed(HiddenRange r) => r != _editing && !_revealed.contains(r);

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
    _revealed = {};

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
    if (sel != old.selection) _revealed = {};

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
    _revealed = {};
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
    _revealed = {};
    _setInternal(
      value.copyWith(
        selection: TextSelection.collapsed(offset: box.end),
        composing: TextRange.empty,
      ),
    );
  }

  /// `보기`: 박스 어절들을 잠시 연다. (F4-4)
  void reveal(List<HiddenRange> boxes) {
    if (boxes.isEmpty) return;
    _editing = null;
    _revealed = boxes.toSet();
    _setInternal(
      value.copyWith(
        selection: TextSelection.collapsed(offset: boxes.last.end),
        composing: TextRange.empty,
      ),
    );
  }

  /// 수정 모드에서 이전(-1)/다음(+1) 박스로 이동한다. (F4-2)
  void moveEditing(int step) {
    final i = editingIndex;
    if (i < 0) return;
    final next = i + step;
    if (next < 0 || next >= _hidden.length) return;
    startEditing(_hidden[next]);
  }

  /// 수정 모드에서 빠져나온다(✕). 어절은 다시 박스가 된다.
  void stopEditing() {
    if (_editing == null) return;
    _editing = null;
    _history.breakGroup();
    notifyListeners();
  }

  /// 메뉴 대상 박스: 선택에 일부라도 걸친 박스들.
  /// 선택이 없으면(우클릭 등) [pressedOffset] 위치의 박스. (F4-1)
  List<HiddenRange> boxesForMenu({int? pressedOffset}) {
    final sel = selection;
    if (sel.isValid && !sel.isCollapsed) {
      return _hidden
          .where((r) => isBoxed(r) && r.overlaps(sel.start, sel.end))
          .toList();
    }
    if (pressedOffset == null) return const [];
    final box = boxAt(pressedOffset);
    return box == null ? const [] : [box];
  }

  /// `해제`: 지정한 박스들의 가린 범위를 푼다. (F3-3)
  void unhideBoxes(List<HiddenRange> boxes) {
    if (boxes.isEmpty) return;
    final remove = boxes.toSet();
    final sel = selection.isValid && !selection.isCollapsed
        ? selection
        : TextSelection.collapsed(offset: boxes.last.end);
    _applyAction(_hidden.where((r) => !remove.contains(r)).toList(), sel);
  }

  /// 화면 아무 곳이나 누르면 `보기`로 연 박스를 다시 가린다. (F4-4)
  void dismissReveal() {
    if (_revealed.isEmpty) return;
    _revealed = {};
    notifyListeners();
  }

  void undo() => _restore(_history.undo(_snapshot));

  void redo() => _restore(_history.redo(_snapshot));

  void _restore(EditorSnapshot? s) {
    if (s == null) return;
    _hidden = s.hidden;
    _editing = null;
    _revealed = {};
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
