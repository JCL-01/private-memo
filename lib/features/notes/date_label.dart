/// 메모 목록에 표시할 날짜 문자열.
/// 오늘이면 '오후 3:05', 어제면 '어제', 그 외에는 '2026. 11. 19.'.
String formatNoteDate(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;

  if (diff == 0) {
    final period = date.hour < 12 ? '오전' : '오후';
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$period $hour12:$minute';
  }
  if (diff == 1) return '어제';
  return '${date.year}. ${date.month}. ${date.day}.';
}
