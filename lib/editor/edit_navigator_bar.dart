import 'package:material_ui/material_ui.dart';

import 'box_colors.dart';
import 'private_text_controller.dart';

/// 수정 모드 바: 가운데 파란색 `수정 완료` 버튼. 누르면 수정 모드가 끝난다. (F4-2b)
/// 수정 모드일 때만 보인다.
class EditNavigatorBar extends StatelessWidget {
  const EditNavigatorBar({super.key, required this.controller});

  final PrivateTextController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isEditingBox) return const SizedBox.shrink();
        final blue = focusColorOf(context);
        return Material(
          key: const Key('editNavigatorBar'),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: FilledButton(
                  key: const Key('editDoneButton'),
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor:
                        ThemeData.estimateBrightnessForColor(blue) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  onPressed: controller.stopEditing,
                  child: const Text('수정 완료'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
