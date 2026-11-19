import 'package:flutter_test/flutter_test.dart';
import 'package:private_memo/features/notes/date_label.dart';

void main() {
  final now = DateTime(2026, 11, 19, 18);

  test('오늘은 시간으로 표시', () {
    expect(formatNoteDate(DateTime(2026, 11, 19, 0, 5), now: now), '오전 12:05');
    expect(formatNoteDate(DateTime(2026, 11, 19, 15, 30), now: now), '오후 3:30');
  });

  test('어제와 그 이전', () {
    expect(formatNoteDate(DateTime(2026, 11, 18, 23), now: now), '어제');
    expect(formatNoteDate(DateTime(2026, 1, 2), now: now), '2026. 1. 2.');
  });
}
