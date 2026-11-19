import 'package:material_ui/material_ui.dart';

import 'box_colors.dart';
import 'editor_history.dart';
import 'hidden_ranges.dart';
import 'private_view.dart';

/// 프라이빗 메모 에디터의 텍스트 컨트롤러.
///
/// 사용자가 입력하거나 커서를 옮기면 [value] setter로 들어오므로,
/// 여기서 가린 범위 이동, 박스 안 커서 막기, 되돌리기 기록,
/// 프라이빗 모드의 현재 어절 계산을 한 번에 처리한다.
class PrivateTextController extends TextEditingController {
  PrivateTextController({
    super.text,
    List<HiddenRange> hidden = const [],
    bool privateMode = false,
  }) : _hidden = clampRanges(hidden, text?.length ?? 0),
       _anchor = text?.length ?? 0 {
    _privateMode = privateMode;
  }

  final EditorHistory _history = EditorHistory();

  /// 프라이빗 드래그로 가린 범위(저장됨).
  List<HiddenRange> _hidden;

  /// 수정 모드에서 오갈 어절들(드래그 범위에 걸친 박스). 비어 있으면 수정 모드 아님. (F4-2)
  List<HiddenRange> _targets = [];

  /// 지금 수정 중인 어절의 [_targets] 인덱스.
  int _targetIndex = 0;

  /// `보기`로 잠시 연 어절들. 저장하지 않는다. (F4-4, F4-5)
  Set<HiddenRange> _revealed = {};

  bool _privateMode = false;

  /// 프라이빗 모드의 현재 어절 기준점(커서 위치).
  /// 범위 선택·우클릭 중에는 바뀌지 않아서, 박스를 눌러도 그 어절이 드러나지 않는다.
  int _anchor;

  /// 우클릭으로 커서가 옮겨져도 현재 어절을 바꾸지 않는다.
  bool _holdAnchor = false;

  /// 가장 최근에 수정·추가한 위치. (F2-6 `최근`)
  int? _lastEditOffset;

  bool _internal = false;

  // ───────────────────────── 상태 조회 ─────────────────────────

  List<HiddenRange> get hidden => List.unmodifiable(_hidden);
  Set<HiddenRange> get revealedRanges => Set.unmodifiable(_revealed);
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  /// 프라이빗 모드 여부. (F2)
  bool get privateMode => _privateMode;
  set privateMode(bool on) {
    if (_privateMode == on) return;
    _privateMode = on;
    _revealed = {};
    final sel = selection;
    if (sel.isValid) _anchor = sel.extentOffset;
    notifyListeners();
  }

  /// 프라이빗 모드의 현재 어절 기준점.
  int get anchor => _anchor;

  /// 지금 수정 중인 어절(보이는 상태). 수정 모드가 아니면 null.
  HiddenRange? get editingRange =>
      _targets.isEmpty ? null : _targets[_targetIndex];

  /// 수정 모드 여부. 켜져 있으면 이전/다음/닫기 바를 보여 준다.
  /// ✕를 눌러야만 끝난다. (F4-2b)
  bool get isEditingBox => _targets.isNotEmpty;

  /// 수정 중인 어절이 대상 중 몇 번째인지(0부터). 수정 모드가 아니면 -1.
  int get editingIndex => _targets.isEmpty ? -1 : _targetIndex;

  /// 수정 모드에서 오갈 수 있는 어절 수.
  int get editingCount => _targets.length;

  /// 지금 보이는 특별 범위: 수정 중인 어절 + `보기`로 연 어절.
  List<HiddenRange> get _visible => [?editingRange, ..._revealed];

  /// 글자별 표시 방식(박스, 회색 단계).
  ShadeMap get shades => _privateMode
      ? privateShades(text, _anchor, _visible)
      : normalShades(text, _hidden, _visible);

  /// 지금 박스로 보이는 구간들.
  List<HiddenRange> get boxes => shades.rangesOf(Shade.box);

  /// [r]이 지금 박스로 보이는지.
  bool isBoxed(HiddenRange r) {
    final map = shades;
    if (r.isEmpty || r.end > map.length) return false;
    for (var i = r.start; i < r.end; i++) {
      if (map[i] != Shade.box) return false;
    }
    return true;
  }

  /// 커서 오프셋 [offset]에 걸친 박스.
  HiddenRange? boxAt(int offset) {
    for (final b in boxes) {
      if (b.touches(offset)) return b;
    }
    return null;
  }

  EditorSnapshot get _snapshot => EditorSnapshot(text, selection, _hidden);

  // ───────────────────────── 입력 처리 ─────────────────────────

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
    final editing = editingRange;
    final inEditingWord =
        editing != null &&
        edit.start >= editing.start &&
        edit.oldEnd <= editing.end;
    // 드래그로 가린 어절을 수정할 때만 새 글자도 가린다. (F4-3)
    final editingHiddenWord =
        inEditingWord &&
        _hidden.any((h) => h.overlaps(editing.start, editing.end));

    _history.recordEdit(EditorSnapshot(old.text, old.selection, _hidden), edit);
    _hidden = applyEdit(_hidden, edit, hideInserted: editingHiddenWord);
    _revealed = {};
    final end = cursor ?? edit.start + edit.inserted.length;
    _remapTargets(edit, inEditingWord, end);
    _lastEditOffset = end;
    _anchor = end;
    _holdAnchor = false;
    _setInternal(next);
  }

  void _onSelectionChange(TextEditingValue old, TextEditingValue next) {
    var value = next;
    final sel = next.selection;
    // IME 동기화처럼 커서가 그대로인 값 갱신에서는 `보기`를 유지한다.
    if (sel != old.selection) _revealed = {};

    // 박스를 짧게 누르거나 방향키로 들어오면 박스 앞/뒤로 보낸다. (F4-6)
    if (sel.isValid && sel.isCollapsed && next.composing.isCollapsed) {
      final off = sel.baseOffset;
      final box = boxes.where((b) => b.strictlyContains(off)).firstOrNull;
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

    final newSel = value.selection;
    if (newSel.isValid && newSel.isCollapsed && !_holdAnchor) {
      _anchor = newSel.baseOffset;
    }
    _setInternal(value);
  }

  /// 우클릭 시작: 우클릭으로 커서가 옮겨져도 현재 어절을 바꾸지 않는다.
  void holdAnchor() => _holdAnchor = true;

  /// 일반 클릭·터치 시작: 다시 커서를 따라 현재 어절을 바꾼다.
  void releaseAnchor() => _holdAnchor = false;

  // ───────────────────────── 수정 모드 대상 ─────────────────────────

  /// 편집에 맞춰 수정 대상 어절들을 옮긴다.
  /// 수정 중인 어절이 공백으로 나뉘면 나뉜 조각이 모두 대상이 되고,
  /// 커서가 있는 조각을 계속 수정한다. (F4-3)
  void _remapTargets(TextEdit edit, bool inEditingWord, int cursor) {
    if (_targets.isEmpty) return;
    final next = <HiddenRange>[];
    var nextIndex = -1;
    for (var i = 0; i < _targets.length; i++) {
      final isCurrent = i == _targetIndex;
      final pieces = applyEdit(
        [_targets[i]],
        edit,
        hideInserted: isCurrent && inEditingWord,
      );
      if (isCurrent) {
        if (pieces.isEmpty) {
          nextIndex = next.length; // 지워졌으면 다음 대상으로
        } else {
          final at = pieces.indexWhere((p) => p.touches(cursor));
          nextIndex = next.length + (at < 0 ? pieces.length - 1 : at);
        }
      }
      next.addAll(pieces);
    }
    _setTargets(next, nextIndex);
  }

  /// 되돌리기·가리기·해제처럼 글자나 범위가 통째로 바뀐 뒤 대상을 다시 맞춘다.
  /// 이전 대상과 겹치는 어절들이 새 대상이 된다.
  void _resyncTargets() {
    if (_targets.isEmpty) return;
    final current = editingRange!;
    final len = text.length;
    final next = <HiddenRange>{};
    for (final t in _targets) {
      final a = t.start.clamp(0, len);
      final b = t.end.clamp(0, len);
      next.addAll(wordsOverlapping(text, a, a == b ? a : b));
    }
    final list = next.toList()..sort((x, y) => x.start.compareTo(y.start));
    final at = list.indexWhere((w) => w.overlaps(current.start, current.end));
    _setTargets(list, at < 0 ? _targetIndex : at);
  }

  void _setTargets(List<HiddenRange> next, int index) {
    _targets = next;
    _targetIndex = next.isEmpty ? 0 : index.clamp(0, next.length - 1);
  }

  // ───────────────────────── 메뉴 동작 ─────────────────────────

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
    _revealed = {};
    _resyncTargets();
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

  /// 메뉴 대상 박스: 선택에 일부라도 걸친 박스들.
  /// 선택이 없으면(우클릭 등) [pressedOffset] 위치의 박스. (F4-1)
  List<HiddenRange> boxesForMenu({int? pressedOffset}) {
    final sel = selection;
    final all = boxes;
    if (sel.isValid && !sel.isCollapsed) {
      return all.where((b) => b.overlaps(sel.start, sel.end)).toList();
    }
    if (pressedOffset == null) return const [];
    final box = all.where((b) => b.touches(pressedOffset)).firstOrNull;
    return box == null ? const [] : [box];
  }

  /// `해제`: 지정한 박스들의 가린 범위를 푼다. (F3-3)
  void unhideBoxes(List<HiddenRange> targets) {
    if (targets.isEmpty) return;
    final sel = selection.isValid && !selection.isCollapsed
        ? selection
        : TextSelection.collapsed(offset: targets.last.end);
    final next = _hidden
        .where((h) => !targets.any((t) => h.overlaps(t.start, t.end)))
        .toList();
    _applyAction(next, sel);
  }

  /// `수정`: [targets] 중 첫 어절을 현재 어절로 만들어 편집한다(수정 모드). (F4-2)
  /// 이후 ▲▼로 [targets] 안에서만 오간다.
  void startEditing(List<HiddenRange> targets) {
    if (targets.isEmpty) return;
    _history.breakGroup();
    _setTargets(List.of(targets), 0);
    _revealed = {};
    _moveCursorTo(editingRange!.end);
  }

  /// 수정 모드에서 이전(-1)/다음(+1) 어절로 이동한다. (F4-2a)
  void moveEditing(int step) {
    if (_targets.isEmpty) return;
    final next = _targetIndex + step;
    if (next < 0 || next >= _targets.length) return;
    _history.breakGroup();
    _targetIndex = next;
    _moveCursorTo(editingRange!.end);
  }

  /// 수정 모드에서 빠져나온다(✕). 어절은 다시 박스가 된다. (F4-2b)
  void stopEditing() {
    if (_targets.isEmpty) return;
    _setTargets([], 0);
    _history.breakGroup();
    notifyListeners();
  }

  /// `보기`: 박스들을 잠시 연다. 현재 어절과 커서는 그대로. (F4-4)
  void reveal(List<HiddenRange> targets) {
    if (targets.isEmpty) return;
    _revealed = targets.toSet();
    final sel = selection;
    if (sel.isValid && !sel.isCollapsed) {
      _setInternal(
        value.copyWith(
          selection: TextSelection.collapsed(offset: targets.last.end),
          composing: TextRange.empty,
        ),
      );
    } else {
      notifyListeners();
    }
  }

  /// 화면 아무 곳이나 누르면 `보기`로 연 박스를 다시 가린다. (F4-4)
  void dismissReveal() {
    if (_revealed.isEmpty) return;
    _revealed = {};
    notifyListeners();
  }

  // ───────────────────────── 프라이빗 모드 이동 ─────────────────────────

  /// `최근`: 가장 최근에 수정·추가한 어절로 이동한다. (F2-6)
  void jumpToRecent() {
    final at = _lastEditOffset;
    _moveCursorTo(at == null ? _lastWordEnd : at.clamp(0, text.length));
  }

  /// `마지막`: 문서의 마지막 어절로 이동한다. (F2-7)
  void jumpToLast() => _moveCursorTo(_lastWordEnd);

  int get _lastWordEnd {
    final words = allWords(text);
    return words.isEmpty ? text.length : words.last.end;
  }

  void _moveCursorTo(int offset) {
    _history.breakGroup();
    _anchor = offset;
    _holdAnchor = false;
    _setInternal(
      value.copyWith(
        selection: TextSelection.collapsed(offset: offset),
        composing: TextRange.empty,
      ),
    );
  }

  // ───────────────────────── 되돌리기 ─────────────────────────

  void undo() => _restore(_history.undo(_snapshot));

  void redo() => _restore(_history.redo(_snapshot));

  void _restore(EditorSnapshot? s) {
    if (s == null) return;
    _hidden = s.hidden;
    _revealed = {};
    final selection = s.selection.isValid
        ? s.selection
        : TextSelection.collapsed(offset: s.text.length);
    _anchor = selection.extentOffset;
    _lastEditOffset = selection.extentOffset;
    _setInternal(TextEditingValue(text: s.text, selection: selection));
    _resyncTargets();
    notifyListeners();
  }

  // ───────────────────────── 그리기 ─────────────────────────

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final textColor = style?.color ?? Theme.of(context).colorScheme.onSurface;
    return TextSpan(
      style: style,
      children: buildShadedSpans(
        text: text,
        shades: shades,
        palette: ShadePalette(
          box: boxColorOf(context),
          near: textColor.withValues(alpha: 0.5),
          far: textColor.withValues(alpha: 0.25),
        ),
        composing: withComposing && value.isComposingRangeValid
            ? value.composing
            : null,
      ),
    );
  }
}

/// 박스 막대 두께(글꼴 기본 취소선 두께의 배수).
const double boxThickness = 14;

/// 회색 단계와 박스 색.
class ShadePalette {
  const ShadePalette({required this.box, this.near, this.far});

  final Color box;
  final Color? near;
  final Color? far;
}

/// [shades]에 따라 글자를 그린다.
/// 박스는 글자를 투명하게 하고 회색 배경을 칠한다. 글자가 그대로 있으므로 박스 길이 = 글자 길이.
List<InlineSpan> buildShadedSpans({
  required String text,
  required ShadeMap shades,
  required ShadePalette palette,
  TextRange? composing,
}) {
  if (text.isEmpty) return const [];
  // 배경색은 줄 높이 전체를 칠해 위아래 줄 박스가 붙어 보이므로,
  // 글자를 투명하게 하고 굵은 취소선으로 글자 높이만큼의 막대를 그린다.
  final boxStyle = TextStyle(
    color: const Color(0x00000000),
    decoration: TextDecoration.lineThrough,
    decorationColor: palette.box,
    decorationThickness: boxThickness,
  );
  TextStyle? styleOf(Shade s) => switch (s) {
    Shade.normal => null,
    Shade.near => TextStyle(color: palette.near),
    Shade.far => TextStyle(color: palette.far),
    Shade.box => boxStyle,
  };
  const composingStyle = TextStyle(decoration: TextDecoration.underline);

  bool inComposing(int i) =>
      composing != null && i >= composing.start && i < composing.end;

  final spans = <InlineSpan>[];
  var i = 0;
  while (i < text.length) {
    final shade = shades[i];
    final comp = inComposing(i);
    final start = i;
    while (i < text.length && shades[i] == shade && inComposing(i) == comp) {
      i++;
    }
    var style = styleOf(shade);
    if (comp) style = (style ?? const TextStyle()).merge(composingStyle);
    spans.add(TextSpan(text: text.substring(start, i), style: style));
  }
  return spans;
}

/// 목록 미리보기용: [boxes] 범위만 박스로 그린다.
List<InlineSpan> buildMaskedSpans({
  required String text,
  required List<HiddenRange> boxes,
  required Color boxColor,
}) {
  return buildShadedSpans(
    text: text,
    shades: normalShades(text, boxes, const []),
    palette: ShadePalette(box: boxColor),
  );
}
