import 'package:flutter/material.dart';
import '../../../theme/app_text_styles.dart';

class ModalSheetScaffold extends StatelessWidget {
  const ModalSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding,
    this.showHandle = true,
    this.showDismiss = true,
    this.titleStyle,
    this.useScrollView = true,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final bool showHandle;
  final bool showDismiss;
  final TextStyle? titleStyle;
  final bool useScrollView;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: showHandle ? 8 : 4),
                if (showHandle)
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: titleStyle ??
                              AppTextStyles.subtitle1.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      if (trailing != null) trailing!,
                      if (showDismiss)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  child: useScrollView
                      ? SingleChildScrollView(
                          padding:
                              (padding ?? const EdgeInsets.fromLTRB(16, 0, 16, 20))
                                  .add(EdgeInsets.only(bottom: bottomInset)),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: child,
                        )
                      : Padding(
                          padding:
                              (padding ?? const EdgeInsets.fromLTRB(16, 0, 16, 20))
                                  .add(EdgeInsets.only(bottom: bottomInset)),
                          child: child,
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
