import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:private_memo/spell/hunspell_spell_checker.dart';

void main() {
  late HunspellSpellChecker checker;

  setUpAll(() async {
    checker = await HunspellSpellChecker.load(
      File('assets/dict/ko.aff').readAsStringSync(),
      File('assets/dict/ko.dic').readAsStringSync(),
    );
  });

  test('맞는 말은 통과한다', () {
    for (final w in ['안녕하세요', '회의에서', '나왔다', '됐다', '할게요', '며칠', '먹었습니다']) {
      expect(checker.isCorrect(w), isTrue, reason: w);
    }
  });

  test('대표적인 오타를 잡는다', () {
    for (final w in ['안녕하세여', '나왓다', '됬다', '할께요', '몇일', '먹엇습니다']) {
      expect(checker.isCorrect(w), isFalse, reason: w);
    }
  });

  test('고침 후보를 낸다', () {
    expect(checker.suggest('나왓다'), contains('나왔다'));
  });
}
