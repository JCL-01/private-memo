import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoColors,
        CupertinoTextField,
        CupertinoTheme,
        cupertinoDesktopTextSelectionHandleControls,
        cupertinoTextSelectionHandleControls;
import 'package:flutter/services.dart'
    show SpellCheckResults, SpellCheckService;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:material_ui/material_ui.dart';

import '../spell/windows_spell_check_service.dart';
import 'hidden_ranges.dart';
import 'private_text_controller.dart';

/// 프라이빗 메모 입력창.
///
/// Material [TextField]는 기기 맞춤법 검사 결과가 오면 컨트롤러의 그리기([PrivateTextController.buildTextSpan])를
/// 건너뛰고 글자를 그대로 그려 버린다. 그러면 박스가 사라진다.
/// 그래서 [EditableText]를 직접 써서, 기기 맞춤법 결과(밑줄·대체 단어)는 그대로 받되
/// 그리기는 항상 우리 컨트롤러가 하도록 했다.
///
/// - 기기(안드로이드·iOS)는 박스가 없는 원래 글자를 그대로 받는다. 박스는 화면에만 그려진다. (F6-4)
/// - 밑줄 친 어절을 누르면 기기의 대체 단어 메뉴가 뜬다.
class PrivateField extends StatefulWidget {
  const PrivateField({
    super.key,
    required this.controller,
    required this.editableKey,
    this.focusNode,
    this.style,
    this.scrollController,
    this.contextMenuBuilder,
    this.hintText,
    this.spellCheckService,
  });

  final PrivateTextController controller;
  final GlobalKey<EditableTextState> editableKey;
  final FocusNode? focusNode;
  final TextStyle? style;
  final ScrollController? scrollController;
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final String? hintText;

  /// 테스트용: 기기 맞춤법 검사 대신 쓸 서비스.
  final SpellCheckService? spellCheckService;

  @override
  State<PrivateField> createState() => _PrivateFieldState();
}

/// 윈도우 맞춤법 서비스는 앱 전체에서 하나만 만든다(윈도우 검사기 생성 비용 절약).
final WindowsSpellCheckService _windowsSpellCheck = WindowsSpellCheckService();

class _PrivateFieldState extends State<PrivateField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  late final TextSelectionGestureDetectorBuilder _gestures =
      TextSelectionGestureDetectorBuilder(delegate: this);

  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  bool _showHandles = false;

  @override
  GlobalKey<EditableTextState> get editableTextKey => widget.editableKey;

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => true;

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  // TextField와 같은 규칙으로 선택 손잡이를 보인다.
  void _onSelectionChanged(TextSelection _, SelectionChangedCause? cause) {
    final show =
        _gestures.shouldShowSelectionToolbar &&
        cause != SelectionChangedCause.keyboard &&
        (cause == SelectionChangedCause.longPress ||
            widget.controller.text.isNotEmpty);
    if (show != _showHandles) setState(() => _showHandles = show);
  }

  /// 기기 맞춤법 검사를 켠다.
  /// - 안드로이드·iOS: Flutter가 연결해 주는 기기 맞춤법
  /// - 윈도우: 윈도우 내장 맞춤법 API를 직접 연결한 서비스 (F6-6)
  SpellCheckConfiguration? _spellCheck(TargetPlatform platform) {
    var service = widget.spellCheckService;
    if (service == null &&
        platform == TargetPlatform.windows &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.windows) {
      service = _windowsSpellCheck;
    }
    if (service == null &&
        !WidgetsBinding
            .instance
            .platformDispatcher
            .nativeSpellCheckServiceDefined) {
      return null;
    }
    final base = SpellCheckConfiguration(spellCheckService: service);
    return switch (platform) {
      TargetPlatform.iOS || TargetPlatform.macOS =>
        CupertinoTextField.inferIOSSpellCheckConfiguration(base),
      _ => TextField.inferAndroidSpellCheckConfiguration(base),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platform = theme.platform;
    final selectionTheme = TextSelectionTheme.of(context);

    TextSelectionControls controls;
    Color cursorColor;
    Color? selectionColor;
    var cursorOpacityAnimates = false;
    var paintCursorAboveText = false;
    Offset? cursorOffset;
    Radius? cursorRadius;

    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        final cupertino = CupertinoTheme.of(context);
        controls = platform == TargetPlatform.iOS
            ? cupertinoTextSelectionHandleControls
            : cupertinoDesktopTextSelectionHandleControls;
        cursorColor = selectionTheme.cursorColor ?? cupertino.primaryColor;
        selectionColor =
            selectionTheme.selectionColor ??
            cupertino.primaryColor.withValues(alpha: 0.40);
        cursorOpacityAnimates = true;
        paintCursorAboveText = true;
        cursorRadius = const Radius.circular(2);
        cursorOffset = Offset(-2 / MediaQuery.devicePixelRatioOf(context), 0);
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        controls = materialTextSelectionHandleControls;
        cursorColor = selectionTheme.cursorColor ?? theme.colorScheme.primary;
        selectionColor =
            selectionTheme.selectionColor ??
            theme.colorScheme.primary.withValues(alpha: 0.40);
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        controls = desktopTextSelectionHandleControls;
        cursorColor = selectionTheme.cursorColor ?? theme.colorScheme.primary;
        selectionColor =
            selectionTheme.selectionColor ??
            theme.colorScheme.primary.withValues(alpha: 0.40);
    }

    final style = theme.textTheme.bodyLarge!.merge(widget.style);

    final editable = _PrivateEditableText(
      key: widget.editableKey,
      controller: widget.controller,
      focusNode: _focus,
      style: style,
      cursorColor: cursorColor,
      backgroundCursorColor: CupertinoColors.inactiveGray,
      cursorOpacityAnimates: cursorOpacityAnimates,
      paintCursorAboveText: paintCursorAboveText,
      cursorOffset: cursorOffset,
      cursorRadius: cursorRadius,
      selectionColor: selectionColor,
      selectionControls: controls,
      showSelectionHandles: _showHandles,
      onSelectionChanged: _onSelectionChanged,
      keyboardType: TextInputType.multiline,
      maxLines: null,
      expands: true,
      rendererIgnoresPointer: true,
      scrollController: widget.scrollController,
      contextMenuBuilder: widget.contextMenuBuilder,
      spellCheckConfiguration: _spellCheck(platform),
      magnifierConfiguration: TextMagnifier.adaptiveMagnifierConfiguration,
      mouseCursor: SystemMouseCursors.text,
    );

    return Semantics(
      textField: true,
      multiline: true,
      child: _gestures.buildGestureDetector(
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Stack(
            children: [
              if (widget.hintText != null)
                IgnorePointer(
                  child: ListenableBuilder(
                    listenable: widget.controller,
                    builder: (context, _) => widget.controller.text.isEmpty
                        ? Text(
                            widget.hintText!,
                            style: style.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              editable,
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivateEditableText extends EditableText {
  _PrivateEditableText({
    super.key,
    required super.controller,
    required super.focusNode,
    required super.style,
    required super.cursorColor,
    required super.backgroundCursorColor,
    super.cursorOpacityAnimates,
    super.paintCursorAboveText,
    super.cursorOffset,
    super.cursorRadius,
    super.selectionColor,
    super.selectionControls,
    super.showSelectionHandles,
    super.onSelectionChanged,
    super.keyboardType,
    super.maxLines,
    super.expands,
    super.rendererIgnoresPointer,
    super.scrollController,
    super.contextMenuBuilder,
    super.spellCheckConfiguration,
    super.magnifierConfiguration,
    super.mouseCursor,
  });

  @override
  EditableTextState createState() => _PrivateEditableTextState();
}

class _PrivateEditableTextState extends EditableTextState {
  /// 기기 맞춤법 결과를 컨트롤러에 넘기고, 그리기는 항상 컨트롤러가 한다.
  /// (기본 구현은 맞춤법 결과가 있으면 컨트롤러 그리기를 건너뛰어 박스가 사라진다.)
  @override
  TextSpan buildTextSpan() {
    final c = widget.controller;
    if (c is! PrivateTextController) return super.buildTextSpan();
    c.updateDeviceMisspelled(
      deviceMisspelledRanges(
        spellCheckEnabled ? spellCheckResults : null,
        c.text,
      ),
    );
    return c.buildTextSpan(
      context: context,
      style: widget.style,
      withComposing: !widget.readOnly && widget.focusNode.hasFocus,
    );
  }
}

/// 기기 맞춤법 결과를 지금 글자 기준의 밑줄 범위로 바꾼다.
/// 결과가 조금 늦게 와서 글자가 바뀌어 있으면, 같은 자리에 같은 단어가 남아 있는 것만 쓴다.
@visibleForTesting
List<HiddenRange> deviceMisspelledRanges(
  SpellCheckResults? results,
  String text,
) {
  if (results == null) return const [];
  final checked = results.spellCheckedText;
  final out = <HiddenRange>[];
  for (final span in results.suggestionSpans) {
    final r = span.range;
    if (!r.isValid || r.isCollapsed || r.end > text.length) continue;
    if (checked != text &&
        (r.end > checked.length ||
            checked.substring(r.start, r.end) !=
                text.substring(r.start, r.end))) {
      continue;
    }
    out.add(HiddenRange(r.start, r.end));
  }
  return out;
}
