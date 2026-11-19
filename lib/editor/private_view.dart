/// 화면에 그릴 글자별 표시 방식 계산.
///
/// 일반 모드: 가린 범위는 박스.
/// 프라이빗 모드: 현재 어절은 그대로, 앞뒤 두 어절씩은 회색 단계, 나머지는 박스. (F2)
library;

import 'dart:typed_data';

import 'hidden_ranges.dart';

/// 글자 하나의 표시 방식.
enum Shade {
  /// 그대로 보임(현재 어절, 공백, 일반 글자).
  normal,

  /// 현재 어절 바로 앞·뒤 어절: 회색. (F2-2)
  near,

  /// 현재 어절 두 번째 앞·뒤 어절: 더 옅은 회색. (F2-2)
  far,

  /// 박스.
  box,
}

/// 공백으로 나뉜 모든 어절.
List<HiddenRange> allWords(String text) =>
    text.isEmpty ? const [] : wordsOverlapping(text, 0, text.length);

/// 글자별 표시 방식 목록. 인덱스는 UTF-16 오프셋.
class ShadeMap {
  ShadeMap(this.length) : _codes = Uint8List(length);

  final int length;
  final Uint8List _codes;

  Shade operator [](int i) => Shade.values[_codes[i]];

  void paint(HiddenRange r, Shade s) {
    final a = r.start.clamp(0, length);
    final b = r.end.clamp(0, length);
    for (var i = a; i < b; i++) {
      _codes[i] = s.index;
    }
  }

  /// [shade]로 칠해진 연속 구간들.
  List<HiddenRange> rangesOf(Shade shade) {
    final out = <HiddenRange>[];
    var i = 0;
    while (i < length) {
      if (_codes[i] != shade.index) {
        i++;
        continue;
      }
      final s = i;
      while (i < length && _codes[i] == shade.index) {
        i++;
      }
      out.add(HiddenRange(s, i));
    }
    return out;
  }
}

/// 일반 모드: [hidden] 중 [visible](수정 중·보기 중)을 뺀 부분이 박스.
ShadeMap normalShades(
  String text,
  List<HiddenRange> hidden,
  List<HiddenRange> visible,
) {
  final map = ShadeMap(text.length);
  for (final r in hidden) {
    map.paint(r, Shade.box);
  }
  for (final v in visible) {
    map.paint(v, Shade.normal);
  }
  return map;
}

/// 프라이빗 모드 표시. [anchor]는 커서 위치(현재 어절 기준점).
///
/// - 커서가 어절에 붙어 있으면 그 어절이 현재 어절.
/// - 커서가 공백 사이에 있으면 현재 어절은 없고, 커서 앞뒤 어절부터 회색 단계.
/// - 드래그로 가린 어절이라도 현재·앞뒤 두 어절은 보인다. (F2-9)
/// - [visible](수정 중·보기 중)은 항상 그대로 보인다.
ShadeMap privateShades(String text, int anchor, List<HiddenRange> visible) {
  final map = ShadeMap(text.length);
  final words = allWords(text);
  final current = words.indexWhere((w) => w.touches(anchor));

  // 커서 왼쪽 가장 가까운 어절 인덱스 / 오른쪽 가장 가까운 어절 인덱스
  final int left;
  final int right;
  if (current >= 0) {
    left = current - 1;
    right = current + 1;
  } else {
    final before = words.where((w) => w.end < anchor).length;
    left = before - 1;
    right = before;
  }

  for (var i = 0; i < words.length; i++) {
    final Shade s;
    if (i == current) {
      s = Shade.normal;
    } else if (i == left || i == right) {
      s = Shade.near;
    } else if (i == left - 1 || i == right + 1) {
      s = Shade.far;
    } else {
      s = Shade.box;
    }
    map.paint(words[i], s);
  }
  for (final v in visible) {
    map.paint(v, Shade.normal);
  }
  return map;
}
