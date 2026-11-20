import 'package:material_ui/material_ui.dart';

import '../editor/box_colors.dart';
import '../editor/masked_text.dart';
import '../editor/private_view.dart';
import 'note_blocks.dart';

/// 원본·정리본 박스. 채팅 답변의 코드 블록처럼 상단 바가 있다. (F8-2a, F8-2b)
///
/// 상단 바: 왼쪽 라벨, 오른쪽에 ✕(삭제) · 가위(잘라내기) · 복사. 정리본이 가려져 있으면 `해제`/`가리기`.
/// 스크롤해서 상단 바가 화면 위로 사라지면 바가 박스 아래쪽으로 내려온다. (F8-2c)
class BlockBox extends StatefulWidget {
  const BlockBox({
    super.key,
    required this.block,
    required this.onDelete,
    required this.onCut,
    required this.onCopy,
    this.onToggleReveal,
  });

  final NoteBlock block;
  final VoidCallback onDelete;
  final VoidCallback onCut;
  final VoidCallback onCopy;

  /// 정리본이 가리기 대상일 때만: `해제` / `가리기`.
  final VoidCallback? onToggleReveal;

  @override
  State<BlockBox> createState() => _BlockBoxState();
}

class _BlockBoxState extends State<BlockBox> {
  static const _barHeight = 44.0;
  bool _barAtBottom = false;
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_update);
      _position = position;
      _position?.addListener(_update);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void dispose() {
    _position?.removeListener(_update);
    super.dispose();
  }

  /// 상단 바가 화면 위로 가려졌는지 확인해 바 위치를 정한다.
  void _update() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final scrollable = Scrollable.maybeOf(context);
    final viewport = scrollable?.context.findRenderObject() as RenderBox?;
    if (box == null || viewport == null || !box.hasSize || !box.attached) {
      return;
    }
    final top =
        box.localToGlobal(Offset.zero).dy -
        viewport.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    final atBottom = top < 0 && bottom > _barHeight * 2;
    if (atBottom != _barAtBottom) setState(() => _barAtBottom = atBottom);
  }

  Widget _bar(BuildContext context, {required bool bottom}) {
    final theme = Theme.of(context);
    final b = widget.block;
    final radius = const Radius.circular(12);
    return Container(
      key: Key(bottom ? 'blockBarBottom-${b.label}' : 'blockBar-${b.label}'),
      height: _barHeight,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: bottom
            ? BorderRadius.only(bottomLeft: radius, bottomRight: radius)
            : BorderRadius.only(topLeft: radius, topRight: radius),
      ),
      child: Row(
        children: [
          Text(
            b.label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (widget.onToggleReveal != null)
            TextButton(
              key: Key('blockReveal-${b.label}'),
              onPressed: widget.onToggleReveal,
              child: Text(b.revealed ? '가리기' : '해제'),
            ),
          IconButton(
            key: Key('blockDelete-${b.label}'),
            tooltip: '삭제',
            iconSize: 20,
            icon: const Icon(Icons.close),
            onPressed: widget.onDelete,
          ),
          IconButton(
            key: Key('blockCut-${b.label}'),
            tooltip: '잘라내기',
            iconSize: 20,
            icon: const Icon(Icons.content_cut),
            onPressed: widget.onCut,
          ),
          IconButton(
            key: Key('blockCopy-${b.label}'),
            tooltip: '복사',
            iconSize: 20,
            icon: const Icon(Icons.copy_outlined),
            onPressed: widget.onCopy,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = widget.block;
    final style = theme.textTheme.bodyLarge!.copyWith(
      fontSize: 16,
      height: 1.5,
    );
    final boxes = b.isMasked ? allWords(b.text) : b.hidden;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surfaceContainerLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_barAtBottom) _bar(context, bottom: false),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Text.rich(
              TextSpan(
                style: style,
                children: maskedSpans(
                  text: b.text,
                  boxes: boxes,
                  boxColor: boxColorOf(context),
                  style: style,
                ),
              ),
              key: Key('blockText-${b.label}'),
            ),
          ),
          if (_barAtBottom) _bar(context, bottom: true),
        ],
      ),
    );
  }
}
