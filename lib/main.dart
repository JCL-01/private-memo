import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';

void main() {
  _registerLicenses();
  runApp(const ProviderScope(child: PrivateMemoApp()));
}

/// 앱에 넣은 맞춤법 엔진과 한국어 사전의 라이선스를 앱 라이선스 목록에 등록한다.
void _registerLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'hunspell-dict-ko (한국어 맞춤법 사전)',
    ], await rootBundle.loadString('assets/dict/LICENSE-ko-dictionary.md'));
    yield LicenseEntryWithLineBreaks([
      'universal_spell_check (Hunspell 엔진)',
    ], await rootBundle.loadString('lib/spell/hunspell/LICENSE'));
  });
}
