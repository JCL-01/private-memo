import 'dart:convert';

import '../editor/hidden_ranges.dart';

/// 메모 안의 박스 종류. (F8-2a)
enum BlockKind {
  /// `원본`: 정리하기 전 글.
  original,

  /// `정리본`: 정리한 글.
  organized,
}

/// 메모 안에 담긴 박스 한 개(원본 또는 정리본).
class NoteBlock {
  const NoteBlock({
    required this.kind,
    required this.text,
    this.hidden = const [],
    this.isPrivate = false,
    this.revealed = false,
  });

  final BlockKind kind;
  final String text;

  /// 원본: 프라이빗 드래그로 가린 범위.
  final List<HiddenRange> hidden;

  /// 정리본: 원본에 가린 내용이 있어 가리기 대상인지. (F8-2f)
  final bool isPrivate;

  /// 정리본: `해제`를 눌러 지금 보이는 상태인지. `가리기`를 누르면 다시 가린다.
  final bool revealed;

  /// 지금 전체를 박스로 가려 보여야 하는지.
  bool get isMasked => isPrivate && !revealed;

  String get label => kind == BlockKind.original ? '원본' : '정리본';

  NoteBlock copyWith({bool? revealed}) => NoteBlock(
    kind: kind,
    text: text,
    hidden: hidden,
    isPrivate: isPrivate,
    revealed: revealed ?? this.revealed,
  );

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'text': text,
    if (hidden.isNotEmpty)
      'hidden': [
        for (final r in hidden) [r.start, r.end],
      ],
    if (isPrivate) 'private': true,
    if (revealed) 'revealed': true,
  };

  static NoteBlock fromJson(Map<String, Object?> j) => NoteBlock(
    kind: BlockKind.values.byName(j['kind'] as String),
    text: j['text'] as String? ?? '',
    hidden: [
      for (final r in (j['hidden'] as List?) ?? const [])
        HiddenRange((r as List)[0] as int, r[1] as int),
    ],
    isPrivate: j['private'] == true,
    revealed: j['revealed'] == true,
  );
}

String encodeBlocks(List<NoteBlock> blocks) =>
    jsonEncode([for (final b in blocks) b.toJson()]);

List<NoteBlock> decodeBlocks(String json) {
  if (json.isEmpty) return const [];
  try {
    return [
      for (final j in jsonDecode(json) as List)
        NoteBlock.fromJson((j as Map).cast<String, Object?>()),
    ];
  } catch (_) {
    return const [];
  }
}
