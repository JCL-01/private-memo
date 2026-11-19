import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hunspell_spell_checker.dart';
import 'spell_checker.dart';

/// 앱에서 쓰는 맞춤법 검사기. 앱을 켜면 한국어 사전을 불러오기 시작하고,
/// 다 불러오면 값이 채워진다. 불러오는 동안에는 밑줄이 없다.
final spellCheckerProvider = FutureProvider<SpellChecker>((ref) async {
  final aff = await rootBundle.loadString('assets/dict/ko.aff', cache: false);
  final dic = await rootBundle.loadString('assets/dict/ko.dic', cache: false);
  return HunspellSpellChecker.load(aff, dic);
});
