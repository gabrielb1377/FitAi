import 'package:flutter/material.dart';

import '../../../../design_system/components/fit_icon_button.dart';
import '../../../../design_system/tokens/fit_icons.dart';
import '../../../../design_system/tokens/fit_layout.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

/// Barra superior controlada pela tela, sem conhecimento de rotas globais.
class FitTopBar extends StatelessWidget implements PreferredSizeWidget {
  const FitTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.showBackButton = false,
    this.onBack,
    this.backTooltip = 'Voltar',
    this.actions = const [],
    this.centerTitle = false,
  }) : assert(!showBackButton || onBack != null),
       assert(leading == null || !showBackButton);

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBack;
  final String backTooltip;
  final List<Widget> actions;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(FitLayout.topBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: centerTitle,
      toolbarHeight: FitLayout.topBarHeight,
      leading: showBackButton
          ? FitIconButton(
              icon: FitIcons.back,
              tooltip: backTooltip,
              onPressed: onBack,
            )
          : leading,
      titleSpacing: FitSpacing.s16,
      title: Semantics(
        header: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: centerTitle
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
      ),
      actions: actions,
    );
  }
}
