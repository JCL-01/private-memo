import 'todo_extractor.dart';

/// 메모 요약기. 내장 AI 모델이 붙기 전에는 [NoSummarizer]를 쓴다. (F8-3)
abstract class MemoSummarizer {
  Future<List<String>> summarize(String memo);
}

/// 요약 없이 할 일만 정리한다.
class NoSummarizer implements MemoSummarizer {
  const NoSummarizer();

  @override
  Future<List<String>> summarize(String memo) async => const [];
}

/// 정리 결과: 요약 + 할 일. (F8-2d)
class OrganizeResult {
  const OrganizeResult({required this.summary, required this.todos});

  final List<String> summary;
  final List<TodoItem> todos;

  bool get isEmpty => summary.isEmpty && todos.isEmpty;

  /// 정리본 글. 할 일이 없으면 요약만, 할 일에 일정이 있으면 그 항목에 붙인다.
  String toText() {
    if (isEmpty) return '정리할 할 일이나 요약을 찾지 못했습니다.';
    final out = StringBuffer();
    if (summary.isNotEmpty) {
      out.writeln('요약');
      for (final s in summary) {
        out.writeln('- $s');
      }
    }
    if (todos.isNotEmpty) {
      if (summary.isNotEmpty) out.writeln();
      out.writeln('할 일');
      // 다른 사람이 맡은 일이 있으면 사람별로 나눈다. 내 일이 먼저.
      final owners = <String>[''];
      for (final t in todos) {
        if (!owners.contains(t.owner)) owners.add(t.owner);
      }
      final split = owners.length > 1;
      for (final owner in owners) {
        final mine = todos.where((t) => t.owner == owner).toList();
        if (mine.isEmpty) continue;
        if (split) out.writeln(owner.isEmpty ? '[나]' : '[$owner]');
        for (final t in mine) {
          out.writeln('- ${t.task}${t.when.isEmpty ? '' : ' (${t.when})'}');
          for (final d in t.details) {
            out.writeln('  · $d');
          }
        }
      }
    }
    return out.toString().trimRight();
  }
}

/// 러프한 메모를 정리한다. 할 일·일정은 규칙으로, 요약은 [summarizer]로.
Future<OrganizeResult> organizeMemo(
  String memo, {
  MemoSummarizer summarizer = const NoSummarizer(),
}) async {
  final todos = extractTodos(memo);
  final summary = await summarizer.summarize(memo);
  return OrganizeResult(summary: summary, todos: todos);
}
