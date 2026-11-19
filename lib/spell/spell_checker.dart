/// 맞춤법 검사기. 모든 검사는 기기 안에서만 한다(메모 내용을 외부로 보내지 않음). (F6-1)
abstract class SpellChecker {
  /// [word]가 사전에 있는(맞는) 단어인지.
  bool isCorrect(String word);
}

/// 사전이 아직 없을 때 쓰는 검사기: 모든 단어를 맞다고 본다.
class NoSpellChecker implements SpellChecker {
  const NoSpellChecker();

  @override
  bool isCorrect(String word) => true;
}
