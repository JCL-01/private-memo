import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'spell_checker.dart';

/// 앱에서 쓰는 맞춤법 검사기. 사전 로딩이 끝나면 값이 채워진다.
///
/// 한국어 사전 엔진은 아직 정하지 않아, 지금은 아무것도 틀렸다고 하지 않는 검사기를 쓴다.
final spellCheckerProvider = FutureProvider<SpellChecker>(
  (ref) async => const NoSpellChecker(),
);
