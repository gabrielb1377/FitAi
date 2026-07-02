import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppPremiumButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final bool fullWidth;
  final bool compact;

  const AppPremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.fullWidth = true,
    this.compact = false,
  });

  const AppPremiumButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.compact = false,
  }) : variant = AppButtonVariant.primary;

  const AppPremiumButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.compact = false,
  }) : variant = AppButtonVariant.secondary;

  const AppPremiumButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.compact = false,
  }) : variant = AppButtonVariant.ghost;

  const AppPremiumButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.compact = false,
  }) : variant = AppButtonVariant.danger;

  @override
  State<AppPremiumButton> createState() => _AppPremiumButtonState();
}

class _AppPremiumButtonState extends State<AppPremiumButton> {
  bool _pressed = false;
  bool _hovered = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final colors = _AppButtonColors.fromVariant(widget.variant);
    final height = widget.compact ? 44.0 : 50.0;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: AnimatedScale(
        scale: _pressed && _enabled ? 0.975 : (_hovered && _enabled ? 1.01 : 1),
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        child: SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _enabled ? widget.onPressed : null,
              onHover: _enabled
                  ? (hovered) {
                      if (_hovered != hovered) {
                        setState(() => _hovered = hovered);
                      }
                    }
                  : null,
              onTapDown: _enabled
                  ? (_) {
                      setState(() => _pressed = true);
                    }
                  : null,
              onTapCancel: () {
                if (_pressed) setState(() => _pressed = false);
              },
              onTapUp: (_) {
                if (_pressed) setState(() => _pressed = false);
              },
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _enabled
                      ? colors.background
                      : AppColors.surfaceVariant.withAlpha(120),
                  gradient: _enabled ? colors.gradient : null,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: _enabled
                        ? colors.border
                        : Colors.white.withAlpha(18),
                  ),
                  boxShadow: [
                    if (_enabled && widget.variant == AppButtonVariant.primary)
                      BoxShadow(
                        color: AppColors.primary.withAlpha(_hovered ? 52 : 30),
                        blurRadius: _hovered ? 24 : 18,
                        spreadRadius: -10,
                        offset: const Offset(0, 12),
                      ),
                    if (_enabled && widget.variant != AppButtonVariant.ghost)
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 18,
                        spreadRadius: -12,
                        offset: const Offset(0, 10),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: widget.fullWidth
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.loading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: colors.foreground,
                        ),
                      )
                    else if (widget.icon != null)
                      Icon(widget.icon, size: 19, color: colors.foreground),
                    if (widget.loading || widget.icon != null)
                      const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _enabled
                              ? colors.foreground
                              : AppColors.textHint,
                          fontSize: widget.compact ? 13 : 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppIconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color color;

  const AppIconActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: _AnimatedIconActionButton(
        icon: icon,
        onPressed: onPressed,
        color: color,
      ),
    );
  }
}

class _AnimatedIconActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const _AnimatedIconActionButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  State<_AnimatedIconActionButton> createState() =>
      _AnimatedIconActionButtonState();
}

class _AnimatedIconActionButtonState extends State<_AnimatedIconActionButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return AnimatedScale(
      scale: _pressed && enabled ? 0.94 : (_hovered && enabled ? 1.04 : 1),
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          onHover: enabled
              ? (hovered) {
                  if (_hovered != hovered) setState(() => _hovered = hovered);
                }
              : null,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: () {
            if (_pressed) setState(() => _pressed = false);
          },
          onTapUp: (_) {
            if (_pressed) setState(() => _pressed = false);
          },
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.color.withAlpha(_hovered ? 36 : 24),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: widget.color.withAlpha(70)),
              boxShadow: [
                if (_hovered)
                  BoxShadow(
                    color: widget.color.withAlpha(24),
                    blurRadius: 20,
                    spreadRadius: -10,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: Icon(widget.icon, color: widget.color, size: 21),
          ),
        ),
      ),
    );
  }
}

class _AppButtonColors {
  final Color background;
  final Color foreground;
  final Color border;
  final LinearGradient? gradient;

  const _AppButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
    this.gradient,
  });

  factory _AppButtonColors.fromVariant(AppButtonVariant variant) {
    switch (variant) {
      case AppButtonVariant.primary:
        return const _AppButtonColors(
          background: AppColors.primary,
          foreground: Colors.black,
          border: Colors.transparent,
          gradient: AppColors.gradientPrimary,
        );
      case AppButtonVariant.secondary:
        return _AppButtonColors(
          background: AppColors.surfaceVariant,
          foreground: AppColors.primary,
          border: AppColors.primary.withAlpha(96),
        );
      case AppButtonVariant.ghost:
        return _AppButtonColors(
          background: Colors.transparent,
          foreground: AppColors.textPrimary,
          border: Colors.white.withAlpha(28),
        );
      case AppButtonVariant.danger:
        return const _AppButtonColors(
          background: Color(0xFFCF6679),
          foreground: Colors.white,
          border: Colors.transparent,
          gradient: LinearGradient(
            colors: [Color(0xFFCF6679), Color(0xFFB71C1C)],
          ),
        );
    }
  }
}

class AppPremiumHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? eyebrow;
  final IconData icon;
  final LinearGradient gradient;
  final Widget? trailing;

  const AppPremiumHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.eyebrow,
    this.gradient = AppColors.gradientPrimary,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AppGradientCard(
      gradient: gradient,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(24),
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(color: Colors.black.withAlpha(22)),
            ),
            child: Icon(icon, color: Colors.black, size: 30),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null && eyebrow!.trim().isNotEmpty) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, height: 1.35),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

class AppMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? width;

  const AppMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(42),
            blurRadius: 18,
            spreadRadius: -12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );

    if (width == null) return child;
    return SizedBox(width: width, child: child);
  }
}

class AppMetricWrap extends StatelessWidget {
  final List<Widget> children;
  final double minTileWidth;

  const AppMetricWrap({
    super.key,
    required this.children,
    this.minTileWidth = 150,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minTileWidth).floor().clamp(
          1,
          4,
        );
        final spacing = AppSpacing.sm;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class AppAnimatedEntrance extends StatelessWidget {
  final Widget child;
  final int index;
  final Offset offset;

  const AppAnimatedEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = const Offset(0, 0.04),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.normal + Duration(milliseconds: index * 35),
      curve: AppMotion.curve,
      builder: (context, value, child) {
        final opacity = value.clamp(0.0, 1.0).toDouble();

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(
              offset.dx * (1 - value),
              offset.dy * 160 * (1 - value),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class AppPremiumDivider extends StatelessWidget {
  const AppPremiumDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withAlpha(0),
            Colors.white.withAlpha(28),
            Colors.white.withAlpha(0),
          ],
        ),
      ),
    );
  }
}
