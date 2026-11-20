import 'package:flutter/services.dart' show TextSelection;

import 'hidden_ranges.dart';

/// 되돌리기 기록 한 칸: 글자 + 커서 위치 + 가린 범위. (F5-3)
class EditorSnapshot {
  const EditorSnapshot(this.text, this.selection, this.hidden);

  final String text;
  final TextSelection selection;
  final List<HiddenRange> hidden;
}

enum _EditKind { insert, delete }

/// 되돌리기/다시 실행 기록.
///
/// 글자 입력은 어절 단위로 묶는다. 공백 뒤에 새 어절을 쓰기 시작하면 새 묶음. (F5-5)
/// 한글 조합처럼 방금 넣은 글자를 바꾸는 입력은 같은 묶음으로 본다.
class EditorHistory {
  EditorHistory({this.limit = 500});

  final int limit;
  final _undo = <EditorSnapshot>[];
  final _redo = <EditorSnapshot>[];

  _EditKind? _lastKind;
  int? _lastEnd;
  bool _lastInsertEndedWithSpace = false;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// 기록을 모두 지운다.
  void clear() {
    _undo.clear();
    _redo.clear();
    breakGroup();
  }

  /// 다음 입력이 반드시 새 묶음이 되도록 한다.
  void breakGroup() {
    _lastKind = null;
    _lastEnd = null;
    _lastInsertEndedWithSpace = false;
  }

  /// 글자 편집을 기록한다. [before]는 편집 직전 상태.
  void recordEdit(EditorSnapshot before, TextEdit edit) {
    final kind = edit.inserted.isEmpty ? _EditKind.delete : _EditKind.insert;
    final bool contiguous;
    if (_lastEnd == null || kind != _lastKind) {
      contiguous = false;
    } else if (kind == _EditKind.insert) {
      // 이어서 입력(start == lastEnd) 또는 방금 넣은 글자를 바꿈(한글 조합)
      contiguous = edit.start <= _lastEnd! && edit.oldEnd == _lastEnd;
    } else {
      contiguous = edit.oldEnd == _lastEnd;
    }

    final startsWord =
        kind == _EditKind.insert &&
        _lastInsertEndedWithSpace &&
        !isWhitespaceUnit(edit.inserted.codeUnitAt(0));

    if (!contiguous || startsWord) _push(before);
    _redo.clear();

    _lastKind = kind;
    if (kind == _EditKind.insert) {
      _lastEnd = edit.start + edit.inserted.length;
      _lastInsertEndedWithSpace = isWhitespaceUnit(
        edit.inserted.codeUnitAt(edit.inserted.length - 1),
      );
    } else {
      _lastEnd = edit.start;
      _lastInsertEndedWithSpace = false;
    }
  }

  /// `프라이빗`/`해제`처럼 한 번에 하나의 되돌리기 단위인 작업을 기록한다.
  void recordAction(EditorSnapshot before) {
    _push(before);
    _redo.clear();
    breakGroup();
  }

  EditorSnapshot? undo(EditorSnapshot current) {
    if (_undo.isEmpty) return null;
    _redo.add(current);
    breakGroup();
    return _undo.removeLast();
  }

  EditorSnapshot? redo(EditorSnapshot current) {
    if (_redo.isEmpty) return null;
    _undo.add(current);
    breakGroup();
    return _redo.removeLast();
  }

  void _push(EditorSnapshot s) {
    _undo.add(s);
    if (_undo.length > limit) _undo.removeAt(0);
  }
}
