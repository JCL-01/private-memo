import 'dart:async';

import '../editor/hidden_ranges.dart';
import '../editor/private_text_controller.dart';
import 'spell_checker.dart';
import 'spell_words.dart';

/// 입력이 멈추면 어절들의 맞춤법을 검사해 컨트롤러에 밑줄 범위를 알려 준다. (F6-2, F6-3)
///
/// - 같은 단어는 한 번만 검사한다(결과를 기억). 그래서 바뀐 어절만 새로 검사된다.
/// - 지금 쓰고 있는 어절(커서가 붙은 어절)은 다 쓰기 전이므로 밑줄을 긋지 않는다.
class SpellCheckRunner {
  SpellCheckRunner(
    this.controller, {
    SpellChecker? checker,
    this.delay = const Duration(milliseconds: 600),
  }) : _checker = checker ?? const NoSpellChecker() {
    controller.addListener(_onChanged);
    _schedule();
  }

  final PrivateTextController controller;
  final Duration delay;
  SpellChecker _checker;
  final Map<String, bool> _cache = {};
  Timer? _timer;
  String? _lastText;
  int? _lastCursor;

  /// 사전을 다 불러온 뒤 검사기를 바꾼다.
  set checker(SpellChecker c) {
    _checker = c;
    _cache.clear();
    _lastText = null;
    _schedule();
  }

  void _onChanged() {
    final cursor = controller.selection.extentOffset;
    if (controller.text == _lastText && cursor == _lastCursor) return;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(delay, runNow);
  }

  /// 바로 검사한다(테스트·사전 로드 직후용).
  void runNow() {
    _timer?.cancel();
    final text = controller.text;
    final cursor = controller.selection.isValid
        ? controller.selection.extentOffset
        : -1;
    _lastText = text;
    _lastCursor = cursor;
    final bad = <HiddenRange>[];
    for (final w in checkableWords(text)) {
      if (w.touches(cursor) && controller.selection.isCollapsed) continue;
      final word = text.substring(w.start, w.end);
      final ok = _cache.putIfAbsent(word, () => _checker.isCorrect(word));
      if (!ok) bad.add(w);
    }
    controller.setMisspelled(bad);
  }

  void dispose() {
    _timer?.cancel();
    controller.removeListener(_onChanged);
  }
}
