import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:win32/win32.dart';

/// 윈도우 내장 맞춤법 검사(Windows Spell Checking API, ISpellChecker)를 쓰는 서비스. (F6-6)
///
/// Flutter는 윈도우에서 기기 맞춤법을 지원하지 않아서, 윈도우 API를 직접 부른다.
/// 메모 내용은 윈도우 안에서만 검사되고 외부로 나가지 않는다.
///
/// 언어는 한국어(ko-KR)를 먼저 쓰고, 없으면 앱 언어, 그다음 영어(en-US)를 쓴다.
/// 윈도우에 해당 언어의 맞춤법 검사가 없으면 아무것도 표시하지 않는다.
final RegExp _hangul = RegExp(r'[가-힣ㄱ-ㅎㅏ-ㅣ]');

class WindowsSpellCheckService implements SpellCheckService {
  ISpellChecker? _checker;
  bool _initialized = false;

  /// 실제로 쓰는 언어 태그(예: ko-KR). 맞춤법 검사를 쓸 수 없으면 null.
  String? languageTag;

  ISpellChecker? _ensureChecker(Locale locale) {
    if (_initialized) return _checker;
    _initialized = true;
    try {
      // 이미 초기화되어 있으면 S_FALSE 등이 오지만 그대로 진행한다.
      final hr = CoInitializeEx(COINIT_APARTMENTTHREADED);
      _log('COM 초기화 결과: 0x${hr.code.toUnsigned(32).toRadixString(16)}');
      final factory = createInstance<ISpellCheckerFactory>(SpellCheckerFactory);
      _log('윈도우에 설치된 맞춤법 언어: ${_supportedLanguages(factory)}');
      try {
        for (final tag in {'ko-KR', locale.toLanguageTag(), 'en-US'}) {
          final p = tag.toPcwstr();
          try {
            final ok = factory.isSupported(p);
            _log('$tag 지원: $ok');
            if (ok) {
              _checker = factory.createSpellChecker(p);
              languageTag = tag;
              break;
            }
          } finally {
            free(p);
          }
        }
      } finally {
        factory.release();
      }
    } catch (e) {
      _log('맞춤법 검사기를 만들지 못함: $e');
      _checker = null;
    }
    _log('사용하는 언어: ${languageTag ?? '없음(맞춤법 꺼짐)'}');
    return _checker;
  }

  @override
  Future<List<SuggestionSpan>?> fetchSpellCheckSuggestions(
    Locale locale,
    String text,
  ) async {
    _log('검사 요청 받음 (앱 언어 ${locale.toLanguageTag()})');
    final checker = _ensureChecker(locale);
    if (checker == null) return null;
    final spans = <SuggestionSpan>[];
    final p = text.toPcwstr();
    IEnumSpellingError? errors;
    final out = calloc<VTablePointer>();
    try {
      errors = checker.check(p);
      if (errors == null) return spans;
      while (errors.next(out) == S_OK) {
        final error = ISpellingError(out.value);
        try {
          final start = error.startIndex;
          final end = start + error.length;
          if (start < 0 || end > text.length || start >= end) continue;
          // 한국어 검사기가 없어 다른 언어로 검사할 때는 한글 어절을 건드리지 않는다.
          if (languageTag != 'ko-KR' &&
              _hangul.hasMatch(text.substring(start, end))) {
            continue;
          }
          spans.add(
            SuggestionSpan(
              TextRange(start: start, end: end),
              _suggestionsFor(checker, error, text.substring(start, end)),
            ),
          );
        } finally {
          error.release();
        }
      }
    } catch (e) {
      _log('검사 중 오류: $e');
      return null;
    } finally {
      _log('검사: 글자 ${text.length}자, 틀린 곳 ${spans.length}개');
      errors?.release();
      free(out);
      free(p);
    }
    return spans;
  }

  List<String> _suggestionsFor(
    ISpellChecker checker,
    ISpellingError error,
    String word,
  ) {
    if (error.correctiveAction == CORRECTIVE_ACTION_REPLACE) {
      final r = error.replacement;
      try {
        return [r.toDartString()];
      } finally {
        CoTaskMemFree(r);
      }
    }
    if (error.correctiveAction != CORRECTIVE_ACTION_GET_SUGGESTIONS) {
      return const [];
    }
    final out = <String>[];
    final w = word.toPcwstr();
    final item = calloc<Pointer<Utf16>>();
    IEnumString? list;
    try {
      list = checker.suggest(w);
      while (list != null &&
          out.length < 5 &&
          list.next(1, item, null) == S_OK) {
        final s = PWSTR(item.value);
        out.add(s.toDartString());
        CoTaskMemFree(s);
      }
    } catch (_) {
      // 후보를 못 얻어도 밑줄은 그대로 보인다.
    } finally {
      list?.release();
      free(item);
      free(w);
    }
    return out;
  }

  List<String> _supportedLanguages(ISpellCheckerFactory factory) {
    final out = <String>[];
    final item = calloc<Pointer<Utf16>>();
    IEnumString? list;
    try {
      list = factory.supportedLanguages;
      while (list != null && list.next(1, item, null) == S_OK) {
        final s = PWSTR(item.value);
        out.add(s.toDartString());
        CoTaskMemFree(s);
      }
    } catch (e) {
      out.add('(목록 오류: $e)');
    } finally {
      list?.release();
      free(item);
    }
    return out;
  }

  /// 개발 중(flutter run) 콘솔에만 찍는 진단 로그.
  void _log(String message) {
    if (kDebugMode) debugPrint('[맞춤법] $message');
  }
}
