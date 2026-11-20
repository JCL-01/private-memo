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

  /// [_targets] 각각이 드래그로 가린 어절인지. 가린 어절이면 수정 중 새로 쓴 글자도 가린다.
  List<bool> _targetHidden = [];

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

  /// 프라이빗 모드에서 수정 모드에 들어가기 전 커서 위치. ✕로 나오면 여기로 돌아간다.
  int? _returnOffset;

  bool _internal = false;

  /// 기기(안드로이드·iOS) 맞춤법 검사가 틀렸다고 알려 준 범위. 화면을 그릴 때 입력창이 채운다. (F6)
  List<HiddenRange> _deviceMisspelled = const [];

  // ───────────────────────── 상태 조회 ─────────────────────────

  List<HiddenRange> get hidden => List.unmodifiable(_hidden);

  /// 기기 맞춤법 밑줄을 그을 범위.
  List<HiddenRange> get deviceMisspelled => _deviceMisspelled;

  /// 기기 맞춤법 검사 결과를 받는다. 화면을 그리는 중에 불리므로 알림은 보내지 않는다.
  void updateDeviceMisspelled(List<HiddenRange> ranges) {
    _deviceMisspelled = ranges;
  }

  /// [offset]이 기기 맞춤법 밑줄 어절 위(경계 포함)인지.
  bool _onDeviceMisspelled(int offset) =>
      _deviceMisspelled.any((m) => m.touches(offset));

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

  /// 프라이빗 모드의 현재 어절(커서가 붙어 있는 어절). 공백 위면 null.
  HiddenRange? get currentWord {
    for (final w in wordsOverlapping(text, _anchor, _anchor)) {
      return w;
    }
    return null;
  }

  /// 지금 수정 중인 어절(보이는 상태). 수정 모드가 아니면 null.
  HiddenRange? get editingRange =>
      _targets.isEmpty ? null : _targets[_targetIndex];

  /// 수정 모드 여부. 켜져 있으면 이전/다음/닫기 바를 보여 준다.
  /// ✕를 눌러야만 끝난다. (F4-2b)
  bool get isEditingBox => _targets.isNotEmpty;

  /// 수정 모드에서 오갈 수 있는 어절 수.
  int get editingCount => _targets.length;

  /// 수정 모드에서 박스가 풀린 어절들(수정 범위의 모든 어절). (F4-2)
  List<HiddenRange> get editingRanges => List.unmodifiable(_targets);

  /// 글자별 표시 방식(박스, 회색 단계).
  ShadeMap get shades => _privateMode
      ? privateShades(text, _anchor, editing: _targets, revealed: _revealed)
      : normalShades(text, _hidden, editing: _targets, revealed: _revealed);

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
    // 수정 범위 안 어느 어절에서든 고칠 수 있다. 고친 어절이 지금 수정 중인 어절이 된다.
    final hit = _targets.indexWhere(
      (t) => edit.start >= t.start && edit.oldEnd <= t.end,
    );
    if (hit >= 0) _targetIndex = hit;
    final inEditingWord = hit >= 0;
    // 드래그로 가린 어절을 수정할 때만 새 글자도 가린다. (F4-3)
    // 어절을 다 지운 뒤 그 자리에 다시 써도 마찬가지다. (F4-2e)
    final editingHiddenWord = inEditingWord && _targetHidden[_targetIndex];
    // 기기 맞춤법 대체 단어처럼, 가린 어절 하나를 통째로(또는 일부를) 바꾼 경우에도 계속 가린다.
    final replacingHiddenWord =
        edit.deleted > 0 &&
        !edit.inserted.codeUnits.any(isWhitespaceUnit) &&
        _hidden.any((h) => edit.start >= h.start && edit.oldEnd <= h.end);

    _history.recordEdit(EditorSnapshot(old.text, old.selection, _hidden), edit);
    _hidden = applyEdit(
      _hidden,
      edit,
      hideInserted: editingHiddenWord || replacingHiddenWord,
    );
    _revealed = {};
    final end = cursor ?? edit.start + edit.inserted.length;
    _remapTargets(edit, inEditingWord, end);
    final ret = _returnOffset;
    if (ret != null && ret > edit.start) {
      _returnOffset = ret >= edit.oldEnd ? ret + edit.delta : edit.start;
    }
    _lastEditOffset = end;
    _holdAnchor = false;

    // 프라이빗 모드에서 현재 어절이 아닌 곳이 바뀐 경우(기기 맞춤법 대체 단어 등):
    // 현재 어절과 커서는 그대로 두고 위치만 따라간다.
    final touchesAnchor = _anchor >= edit.start && _anchor <= edit.oldEnd;
    if (_privateMode && !inEditingWord && !touchesAnchor) {
      if (_anchor > edit.oldEnd) _anchor += edit.delta;
      _setInternal(
        next.copyWith(
          selection: TextSelection.collapsed(offset: _anchor),
          composing: TextRange.empty,
        ),
      );
      return;
    }
    _anchor = end;
    _setInternal(next);
  }

  void _onSelectionChange(TextEditingValue old, TextEditingValue next) {
    var value = next;
    final sel = next.selection;
    // `보기`는 커서가 바뀔 때가 아니라 화면에서 손가락·마우스를 뗄 때 닫는다. (F4-4)

    // 수정 범위 안의 어절로 커서가 가면 그 어절을 지금 수정 중인 어절로 삼는다.
    if (sel.isValid && sel.isCollapsed) {
      final t = _targets.indexWhere((t) => t.touches(sel.baseOffset));
      if (t >= 0) _targetIndex = t;
    }

    // 기기 맞춤법 밑줄 어절을 누르면 기기가 대체 단어를 보여 줄 수 있도록
    // 커서를 그 자리에 그대로 둔다. 박스 앞뒤로 보내거나 되돌리지 않고, 현재 어절도 바꾸지 않는다. (F6-4)
    if (sel.isValid &&
        sel.isCollapsed &&
        next.composing.isCollapsed &&
        _onDeviceMisspelled(sel.baseOffset) &&
        !_targets.any((t) => t.touches(sel.baseOffset))) {
      _setInternal(value);
      return;
    }

    // 프라이빗 모드: 클릭·터치로는 커서와 현재 어절이 바뀌지 않는다.
    // 현재 어절 안에서의 이동(방향키 등)만 허용한다. 현재 어절은 `수정`·`최근`·`마지막`으로만 바꾼다. (F2-10)
    if (_privateMode) {
      if (sel.isValid && sel.isCollapsed && next.composing.isCollapsed) {
        final off = sel.baseOffset;
        final current = currentWord;
        final inTarget = _targets.any((t) => t.touches(off));
        if (inTarget ||
            (current != null && off >= current.start && off <= current.end)) {
          _anchor = off;
        } else if (off != _anchor) {
          value = next.copyWith(
            selection: TextSelection.collapsed(
              offset: _anchor.clamp(0, text.length),
            ),
          );
        }
      }
      _setInternal(value);
      return;
    }

    // 일반 모드: 박스를 짧게 누르거나 방향키로 들어오면 박스 앞/뒤로 보낸다. (F4-6)
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
    final flags = <bool>[];
    var nextIndex = -1;
    for (var i = 0; i < _targets.length; i++) {
      final isCurrent = i == _targetIndex;
      var pieces = applyEdit(
        [_targets[i]],
        edit,
        hideInserted: isCurrent && inEditingWord,
      );
      if (isCurrent) {
        if (pieces.isEmpty) {
          // 어절을 다 지워도 수정 모드는 이어지고, 그 자리가 계속 수정 대상이다. (F4-2e)
          final at = inEditingWord ? edit.start : _targets[i].start;
          pieces = [HiddenRange(at, at)];
          nextIndex = next.length;
        } else {
          final at = pieces.indexWhere((p) => p.touches(cursor));
          nextIndex = next.length + (at < 0 ? pieces.length - 1 : at);
        }
      }
      next.addAll(pieces);
      flags.addAll(List.filled(pieces.length, _targetHidden[i]));
    }
    _setTargets(next, nextIndex, flags);
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
      if (t == current && a == b) {
        next.add(HiddenRange(a, a)); // 비어 있는 수정 자리는 그대로
        continue;
      }
      next.addAll(wordsOverlapping(text, a, a == b ? a : b));
    }
    final list = next.toList()..sort((x, y) => x.start.compareTo(y.start));
    final at = list.indexWhere(
      (w) => w == current || w.overlaps(current.start, current.end),
    );
    final wasHidden = _targetHidden.isNotEmpty && _targetHidden[_targetIndex];
    _setTargets(list, at < 0 ? _targetIndex : at, [
      for (final w in list)
        w.isEmpty ? wasHidden : _hidden.any((h) => h.overlaps(w.start, w.end)),
    ]);
  }

  void _setTargets(List<HiddenRange> next, int index, [List<bool>? hidden]) {
    _targets = next;
    _targetHidden =
        hidden ??
        [for (final t in next) _hidden.any((h) => h.overlaps(t.start, t.end))];
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

  /// `수정`: [targets](수정 범위의 모든 어절)의 박스를 풀어 파란색으로 보이고 편집한다(수정 모드). (F4-2)
  /// 커서는 첫 어절 끝에 놓인다.
  void startEditing(List<HiddenRange> targets) {
    if (targets.isEmpty) return;
    _history.breakGroup();
    if (_privateMode && _targets.isEmpty) _returnOffset = _anchor;
    _setTargets(List.of(targets), 0);
    _revealed = {};
    _moveCursorTo(editingRange!.end);
  }

  /// `수정 완료`(또는 Esc): 수정 모드에서 빠져나온다. 어절들은 다시 박스가 된다. (F4-2b)
  void stopEditing() {
    if (_targets.isEmpty) return;
    _setTargets([], 0);
    _history.breakGroup();
    final ret = _returnOffset;
    _returnOffset = null;
    if (_privateMode && ret != null) {
      // 프라이빗 모드: 수정 전에 쓰던 자리로 돌아간다.
      _moveCursorTo(ret.clamp(0, text.length));
    } else {
      notifyListeners();
    }
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

  /// 프라이빗 모드 화살표: 현재 어절을 이전(-1)/다음(+1) 어절로 옮긴다. (F2-11)
  void moveCurrentWord(int step) {
    final words = allWords(text);
    if (words.isEmpty) return;
    final i = words.indexWhere((w) => w.touches(_anchor));
    final int target;
    if (i >= 0) {
      target = i + step;
    } else {
      final before = words.where((w) => w.end < _anchor).length;
      target = step < 0 ? before - 1 : before;
    }
    if (target < 0 || target >= words.length) return;
    _moveCursorTo(words[target].end);
  }

  /// 프라이빗 모드 화살표 사용 가능 여부.
  bool get canMoveCurrentWordBack {
    final words = allWords(text);
    if (words.isEmpty) return false;
    final i = words.indexWhere((w) => w.touches(_anchor));
    return i >= 0 ? i > 0 : words.first.end < _anchor;
  }

  bool get canMoveCurrentWordForward {
    final words = allWords(text);
    if (words.isEmpty) return false;
    final i = words.indexWhere((w) => w.touches(_anchor));
    return i >= 0 ? i < words.length - 1 : words.last.start > _anchor;
  }

  /// Esc: 수정 모드와 보기를 모두 끝낸다. (F4-10)
  bool exitModes() {
    final had = isEditingBox || _revealed.isNotEmpty;
    _revealed = {};
    if (isEditingBox) {
      stopEditing();
    } else if (had) {
      notifyListeners();
    }
    return had;
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
    _deviceMisspelled = const [];
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
        misspelled: _deviceMisspelled,
        misspelledColor: Theme.of(context).colorScheme.error,
        palette: ShadePalette(
          box: boxColorOf(context),
          near: textColor.withValues(alpha: 0.5),
          focus: focusColorOf(context),
          peek: peekColorOf(context),
        ),
        composing: withComposing && value.isComposingRangeValid
            ? value.composing
            : null,
      ),
    );
  }
}

/// 회색 단계와 박스 색.
class ShadePalette {
  const ShadePalette({required this.box, this.near, this.focus, this.peek});

  final Color box;
  final Color? near;

  /// `수정` 중인 어절 색(파란색). (F4-8)
  final Color? focus;

  /// `보기`로 잠시 연 어절 색(주황색). (F4-8)
  final Color? peek;
}

/// [shades]에 따라 글자를 그린다.
/// 박스는 글자를 투명하게 하고 회색 배경을 칠한다. 글자가 그대로 있으므로 박스 길이 = 글자 길이.
List<InlineSpan> buildShadedSpans({
  required String text,
  required ShadeMap shades,
  required ShadePalette palette,
  TextRange? composing,
  List<HiddenRange> misspelled = const [],
  Color misspelledColor = const Color(0xFFD32F2F),
}) {
  if (text.isEmpty) return const [];
  // 박스 글자는 투명하게만 한다. 회색 박스 자체는 HiddenBoxPainter가
  // 같은 높이로 따로 그린다(글꼴마다 두께가 달라지지 않도록).
  const boxStyle = TextStyle(color: Color(0x00000000));
  TextStyle? styleOf(Shade s) => switch (s) {
    Shade.normal => null,
    Shade.near => TextStyle(color: palette.near),
    Shade.box => boxStyle,
    Shade.focus => TextStyle(color: palette.focus),
    Shade.peek => TextStyle(color: palette.peek),
  };
  const composingStyle = TextStyle(decoration: TextDecoration.underline);

  bool inComposing(int i) =>
      composing != null && i >= composing.start && i < composing.end;
  // 기기 맞춤법 밑줄. 박스 글자는 투명하지만 밑줄은 밑줄 색으로 따로 그려져서
  // 박스 위에도 그대로 보인다. (F6-5)
  bool isMisspelled(int i) => misspelled.any((m) => m.covers(i));
  final misspelledStyle = TextStyle(
    decoration: TextDecoration.underline,
    decorationStyle: TextDecorationStyle.wavy,
    decorationColor: misspelledColor,
  );

  final spans = <InlineSpan>[];
  var i = 0;
  while (i < text.length) {
    final shade = shades[i];
    final comp = inComposing(i);
    final bad = isMisspelled(i);
    final start = i;
    while (i < text.length &&
        shades[i] == shade &&
        inComposing(i) == comp &&
        isMisspelled(i) == bad) {
      i++;
    }
    var style = styleOf(shade);
    if (bad) style = (style ?? const TextStyle()).merge(misspelledStyle);
    if (comp) style = (style ?? const TextStyle()).merge(composingStyle);
    spans.add(TextSpan(text: text.substring(start, i), style: style));
  }
  return spans;
}
