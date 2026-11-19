import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_memo/editor/hidden_ranges.dart';
import 'package:private_memo/editor/private_text_controller.dart';
import 'package:private_memo/spell/spell_check_runner.dart';
import 'package:private_memo/spell/spell_checker.dart';
import 'package:private_memo/spell/spell_words.dart';

const r = HiddenRange.new;

/// 정해 둔 단어만 틀렸다고 하는 검사기. 몇 번 불렸는지 센다.
class FakeChecker implements SpellChecker {
  FakeChecker(this.wrong);
  final Set<String> wrong;
  final calls = <String>[];

  @override
  bool isCorrect(String word) {
    calls.add(word);
    return !wrong.contains(word);
  }
}

void main() {
  group('checkableWords', () {
    test('앞뒤 문장 부호를 빼고 검사한다', () {
      const t = '"안녕하세여!" (나왓다)';
      final words = checkableWords(t);
      expect(words.map((w) => t.substring(w.start, w.end)), ['안녕하세여', '나왓다']);
    });

    test('한글이 없거나 숫자가 섞인 어절은 검사하지 않는다', () {
      const t = 'hello 3시에 만나 OK';
      final words = checkableWords(t);
      expect(words.map((w) => t.substring(w.start, w.end)), ['만나']);
    });
  });

  group('SpellCheckRunner', () {
    test('틀린 어절에 밑줄, 지금 쓰는 어절은 제외 (F2-5, F6-2)', () {
      final c = PrivateTextController(text: '나왓다 그리고 됬다');
      c.selection = const TextSelection.collapsed(offset: 10); // '됬다' 끝
      final runner = SpellCheckRunner(c, checker: FakeChecker({'나왓다', '됬다'}));
      runner.runNow();
      expect(c.misspelled, [r(0, 3)]);

      c.selection = const TextSelection.collapsed(offset: 0);
      runner.runNow();
      expect(c.misspelled, [r(8, 10)]); // 이제 '나왓다'를 쓰는 중
      runner.dispose();
    });

    test('같은 단어는 한 번만 검사한다 (F6-3)', () {
      final checker = FakeChecker({});
      final c = PrivateTextController(text: '오늘 오늘 내일');
      c.selection = const TextSelection.collapsed(offset: 0);
      final runner = SpellCheckRunner(c, checker: checker);
      runner.runNow();
      runner.runNow();
      expect(checker.calls.where((w) => w == '오늘').length, 1);
      expect(checker.calls, ['오늘', '내일']);
      runner.dispose();
    });

    test('입력이 멈춘 뒤에 검사한다', () {
      fakeAsync((async) {
        final c = PrivateTextController(text: '');
        final runner = SpellCheckRunner(c, checker: FakeChecker({'나왓다'}));
        c.value = const TextEditingValue(
          text: '나왓다 ',
          selection: TextSelection.collapsed(offset: 4),
        );
        async.elapse(const Duration(milliseconds: 300));
        expect(c.misspelled, isEmpty);
        async.elapse(const Duration(milliseconds: 400));
        expect(c.misspelled, [r(0, 3)]);
        runner.dispose();
      });
    });
  });

  test('편집하면 고친 어절의 밑줄은 지우고 뒤 밑줄은 따라간다', () {
    final c = PrivateTextController(text: '나왓다 됬다');
    c.setMisspelled([r(0, 3), r(4, 6)]);
    c.value = const TextEditingValue(
      text: '나왔다 됬다',
      selection: TextSelection.collapsed(offset: 3),
    );
    expect(c.misspelled, [r(4, 6)]);
    c.value = const TextEditingValue(
      text: 'X나왔다 됬다',
      selection: TextSelection.collapsed(offset: 1),
    );
    expect(c.misspelled, [r(5, 7)]);
  });
}
