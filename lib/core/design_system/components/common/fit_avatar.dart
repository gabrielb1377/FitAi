import 'package:flutter/material.dart';

import '../../../../design_system/tokens/fit_icons.dart';
import '../../../../design_system/tokens/fit_layout.dart';

/// Tamanhos semânticos disponíveis para [FitAvatar].
enum FitAvatarSize { small, medium, large }

/// Avatar com fallback textual ou icônico e ação opcional.
class FitAvatar extends StatelessWidget {
  const FitAvatar({
    super.key,
    this.image,
    this.name,
    this.icon = FitIcons.person,
    this.size = FitAvatarSize.medium,
    this.onTap,
    this.tooltip,
    this.semanticLabel,
  }) : assert(image != null || name != null || icon != null);

  final ImageProvider<Object>? image;
  final String? name;
  final IconData? icon;
  final FitAvatarSize size;
  final VoidCallback? onTap;
  final String? tooltip;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final diameter = switch (size) {
      FitAvatarSize.small => FitLayout.avatarSmall,
      FitAvatarSize.medium => FitLayout.avatarMedium,
      FitAvatarSize.large => FitLayout.avatarLarge,
    };
    final initials = _initials(name);
    final avatar = CircleAvatar(
      radius: diameter / 2,
      foregroundImage: image,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      child: image != null
          ? null
          : initials == null
          ? Icon(icon)
          : Text(initials, style: Theme.of(context).textTheme.labelLarge),
    );
    final content = onTap == null
        ? avatar
        : SizedBox.square(
            dimension: diameter < FitLayout.minimumTouchTarget
                ? FitLayout.minimumTouchTarget
                : diameter,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Center(child: avatar),
              ),
            ),
          );
    final semantic = Semantics(
      image: onTap == null,
      button: onTap != null,
      label: semanticLabel ?? name ?? 'Avatar',
      child: content,
    );
    return tooltip == null
        ? semantic
        : Tooltip(message: tooltip!, child: semantic);
  }

  String? _initials(String? value) {
    final words = value
        ?.trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .toList();
    if (words == null || words.isEmpty) return null;
    return words.map((word) => word.characters.first.toUpperCase()).join();
  }
}
