import 'package:material_ui/material_ui.dart';

import 'private_text_controller.dart';

/// 수정 모드 바: 이전/다음 박스로 이동, ✕로 빠져나오기. (F4-2)
/// Ctrl+F 찾기 바처럼 수정 모드일 때만 보인다.
class EditNavigatorBar extends StatelessWidget {
  const EditNavigatorBar({super.key, required this.controller});

  final PrivateTextController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isEditingBox) return const SizedBox.shrink();
        final i = controller.editingIndex;
        final n = controller.editingCount;
        final theme = Theme.of(context);
        return Material(
          key: const Key('editNavigatorBar'),
          color: theme.colorScheme.surfaceContainerHigh,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Text('수정 중', style: theme.textTheme.labelLarge),
                  const SizedBox(width: 8),
                  Text('${i + 1}/$n', style: theme.textTheme.bodySmall),
                  const Spacer(),
                  IconButton(
                    key: const Key('editPrevButton'),
                    tooltip: '이전 어절',
                    icon: const Icon(Icons.keyboard_arrow_up),
                    onPressed: i > 0 ? () => controller.moveEditing(-1) : null,
                  ),
                  IconButton(
                    key: const Key('editNextButton'),
                    tooltip: '다음 어절',
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: i < n - 1
                        ? () => controller.moveEditing(1)
                        : null,
                  ),
                  IconButton(
                    key: const Key('editCloseButton'),
                    tooltip: '수정 끝내기',
                    icon: const Icon(Icons.close),
                    onPressed: controller.stopEditing,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
