import 'package:flutter/material.dart';

import '../../../../design_system/components/fit_bottom_sheet.dart';
import '../../../../design_system/components/fit_dialog.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

/// Posiciona um FAB respeitando safe area e espaçamento oficial.
class FitFABContainer extends StatelessWidget {
  const FitFABContainer({
    super.key,
    required this.child,
    this.alignment = Alignment.bottomRight,
    this.padding = const EdgeInsets.all(FitSpacing.s16),
  });

  final Widget child;
  final AlignmentGeometry alignment;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: padding,
      child: Align(alignment: alignment, child: child),
    );
  }
}

/// Nome explícito para o container visual de um bottom sheet FitIA.
class FitBottomSheetContainer extends FitBottomSheet {
  const FitBottomSheetContainer({
    super.key,
    required super.child,
    super.title,
    super.subtitle,
    super.action,
    super.showHandle,
    super.padding,
  });

  /// Exibe o container sem acoplamento com a navegação principal.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    String? subtitle,
    Widget? action,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FitBottomSheetContainer(
        title: title,
        subtitle: subtitle,
        action: action,
        child: child,
      ),
    );
  }
}

/// Nome explícito para a superfície visual de um dialog FitIA.
class FitDialogContainer extends FitDialog {
  const FitDialogContainer({
    super.key,
    required super.title,
    super.message,
    super.content,
    super.icon,
    super.actions,
  });

  /// Exibe o dialog usando o tema e os tokens oficiais.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    IconData? icon,
    List<Widget> actions = const [],
  }) {
    return showDialog<T>(
      context: context,
      builder: (_) => FitDialogContainer(
        title: title,
        message: message,
        content: content,
        icon: icon,
        actions: actions,
      ),
    );
  }
}
