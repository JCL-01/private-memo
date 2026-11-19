import 'dart:isolate';

import 'hunspell/dictionary.dart';
import 'hunspell/hunspell.dart';
import 'spell_checker.dart';

/// Hunspell 한국어 사전으로 검사하는 맞춤법 검사기. 기기 안에서만 동작한다. (F6-1, F6-2)
class HunspellSpellChecker implements SpellChecker {
  HunspellSpellChecker(this._hunspell);

  final Hunspell _hunspell;

  /// 사전 파일 내용([aff], [dic])을 백그라운드에서 읽어 검사기를 만든다.
  /// 사전이 커서(약 14MB) 화면이 멈추지 않도록 별도 isolate에서 해석한다.
  static Future<HunspellSpellChecker> load(String aff, String dic) async {
    final dictionary = await Isolate.run(
      () => HunspellDictionary.parse(aff, dic),
      debugName: 'hunspell-ko',
    );
    return HunspellSpellChecker(Hunspell(dictionary));
  }

  @override
  bool isCorrect(String word) => _hunspell.check(word);

  /// 틀린 단어의 고침 후보(최대 [max]개).
  List<String> suggest(String word, {int max = 5}) =>
      _hunspell.suggest(word, max: max);
}
