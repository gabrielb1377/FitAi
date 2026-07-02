import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_premium_widgets.dart';

export '../theme/app_theme.dart' show AppChip, AppEmptyState;
export 'app_premium_widgets.dart'
    show
        AppAnimatedEntrance,
        AppIconActionButton,
        AppMetricTile,
        AppMetricWrap,
        AppPremiumDivider,
        AppPremiumHeader,
        AppSectionHeader;

enum AppButtonStyle { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final bool loading;
  final bool fullWidth;
  final bool compact;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = AppButtonStyle.primary,
    this.loading = false,
    this.fullWidth = true,
    this.compact = false,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.compact = false,
  }) : style = AppButtonStyle.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.compact = false,
  }) : style = AppButtonStyle.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.compact = false,
  }) : style = AppButtonStyle.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.compact = false,
  }) : style = AppButtonStyle.danger;

  @override
  Widget build(BuildContext context) {
    final variant = switch (style) {
      AppButtonStyle.primary => AppButtonVariant.primary,
      AppButtonStyle.secondary => AppButtonVariant.secondary,
      AppButtonStyle.ghost => AppButtonVariant.ghost,
      AppButtonStyle.danger => AppButtonVariant.danger,
    };

    return AppPremiumButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      variant: variant,
      loading: loading,
      fullWidth: fullWidth,
      compact: compact,
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final LinearGradient? gradient;
  final VoidCallback? onTap;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.gradient,
    this.onTap,
    this.radius = AppRadii.lg,
  });

  @override
  Widget build(BuildContext context) {
    final card = AppGradientCard(
      gradient: gradient,
      padding: padding,
      borderRadius: radius,
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class AppAnimatedCard extends StatelessWidget {
  final Widget child;
  final int index;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AppAnimatedCard({
    super.key,
    required this.child,
    this.index = 0,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppAnimatedEntrance(
      index: index,
      child: AppCard(padding: padding, onTap: onTap, child: child),
    );
  }
}

class AppDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final List<Widget> actions;
  final IconData icon;

  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.actions = const [],
    this.icon = Icons.info_outline_rounded,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    List<Widget> actions = const [],
    IconData icon = Icons.info_outline_rounded,
  }) {
    return showDialog<T>(
      context: context,
      builder: (_) => AppDialog(
        title: title,
        message: message,
        content: content,
        actions: actions,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(icon, color: AppColors.primary),
      title: Text(title),
      content:
          content ??
          (message == null
              ? null
              : Text(message!, style: const TextStyle(color: Colors.white70))),
      actions: actions,
    );
  }
}

class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 24),
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      builder: (_) => AppBottomSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null && title!.trim().isNotEmpty) ...[
              Text(title!, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final int maxLines;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class AppStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return AppMetricTile(label: label, value: value, icon: icon, color: color);
  }
}

class AppMetricCard extends AppStatCard {
  const AppMetricCard({
    super.key,
    required super.label,
    required super.value,
    required super.icon,
    super.color = AppColors.primary,
  });
}

class AppProgressCard extends StatelessWidget {
  final String title;
  final String value;
  final double progress;
  final IconData icon;
  final Color color;

  const AppProgressCard({
    super.key,
    required this.title,
    required this.value,
    required this.progress,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0).toDouble();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInfoRow(icon: icon, label: title, value: value, color: color),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 8,
              color: color,
              backgroundColor: const Color(0xFF2A2A2A),
            ),
          ),
        ],
      ),
    );
  }
}

class AppSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionHeader(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
    );
  }
}

class AppLoading extends StatelessWidget {
  final String message;
  final LinearGradient? gradient;

  const AppLoading({super.key, required this.message, this.gradient});

  @override
  Widget build(BuildContext context) {
    return AppLoadingCard(message: message, gradient: gradient);
  }
}

class AppSkeleton extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadiusGeometry borderRadius;

  const AppSkeleton({
    super.key,
    this.height = 12,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadii.pill)),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 0.85),
      duration: AppMotion.slow,
      curve: Curves.easeInOut,
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(24),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class AppFloatingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool extended;

  const AppFloatingButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.extended = true,
  });

  @override
  Widget build(BuildContext context) {
    if (extended) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: label,
      child: Icon(icon),
    );
  }
}
