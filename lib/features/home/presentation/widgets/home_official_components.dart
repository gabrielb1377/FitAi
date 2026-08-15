import 'package:flutter/material.dart';

import '../../../../core/design_system/components/domain/shared/fit_domain_primitives.dart';
import '../../../../design_system/fit_design_system.dart';

class HomePageBody extends StatelessWidget {
  const HomePageBody({
    super.key,
    required this.children,
    this.onRefresh,
    this.padding,
  });

  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            FitSpacing.s20,
            FitSpacing.s8,
            FitSpacing.s20,
            FitSpacing.s40,
          ),
      children: children,
    );
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: FitBreakpoints.tablet),
        child: list,
      ),
    );
    return onRefresh == null
        ? content
        : RefreshIndicator(onRefresh: onRefresh!, child: content);
  }
}

class HomeFilterStrip extends StatelessWidget {
  const HomeFilterStrip({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(labels.length > 0),
       assert(selectedIndex >= 0 && selectedIndex < labels.length);

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Filtros',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < labels.length; index++) ...[
              FitFilterChip(
                label: labels[index],
                selected: selectedIndex == index,
                onSelected: (_) => onSelected(index),
              ),
              if (index < labels.length - 1)
                const SizedBox(width: FitSpacing.s8),
            ],
          ],
        ),
      ),
    );
  }
}

class HomeMetricGrid extends StatelessWidget {
  const HomeMetricGrid({
    super.key,
    required this.items,
    this.preferredColumns = 4,
    this.embedded = false,
  }) : assert(preferredColumns > 0);

  final List<HomeMetricItem> items;
  final int preferredColumns;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            FitBreakpoints.isSmallMobile(MediaQuery.sizeOf(context).width)
            ? preferredColumns.clamp(1, 2)
            : preferredColumns;
        final width =
            (constraints.maxWidth - (columns - 1) * FitSpacing.s8) / columns;
        return Wrap(
          spacing: FitSpacing.s8,
          runSpacing: FitSpacing.s8,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: HomeMetricTile(item: item, embedded: embedded),
              ),
          ],
        );
      },
    );
  }
}

@immutable
class HomeMetricItem {
  const HomeMetricItem({
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
    this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? detail;
  final Color? color;
  final VoidCallback? onTap;
}

class HomeMetricTile extends StatelessWidget {
  const HomeMetricTile({super.key, required this.item, this.embedded = false});

  final HomeMetricItem item;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final color = item.color ?? Theme.of(context).colorScheme.primary;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(item.icon, size: FitLayout.iconSizeCompact, color: color),
        const SizedBox(height: FitSpacing.s8),
        Text(
          item.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleLarge,
        ),
        const SizedBox(height: FitSpacing.s2),
        Text(
          item.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelSmall,
        ),
        if (item.detail != null) ...[
          const SizedBox(height: FitSpacing.s2),
          Text(
            item.detail!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ],
    );
    final semanticLabel =
        '${item.label}: ${item.value}${item.detail == null ? '' : ', ${item.detail}'}';
    if (embedded) {
      return Semantics(
        button: item.onTap != null,
        label: semanticLabel,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: FitRadius.smallBorder,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FitSpacing.s4,
              vertical: FitSpacing.s8,
            ),
            child: content,
          ),
        ),
      );
    }
    return FitCard(
      onTap: item.onTap,
      variant: item.onTap == null
          ? FitCardVariant.outlined
          : FitCardVariant.clickable,
      padding: const EdgeInsets.all(FitSpacing.s12),
      semanticLabel: semanticLabel,
      child: content,
    );
  }
}

class HomeChartCard extends StatelessWidget {
  const HomeChartCard({
    super.key,
    required this.title,
    required this.points,
    required this.semanticLabel,
    this.subtitle,
    this.color,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final List<FitChartPoint> points;
  final String semanticLabel;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      variant: FitCardVariant.outlined,
      child: FitDomainBarChart(
        points: points,
        semanticLabel: semanticLabel,
        color: color,
      ),
    );
  }
}

class HomeListAction extends StatelessWidget {
  const HomeListAction({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.value,
    this.color,
    this.progress,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final IconData icon;
  final Color? color;
  final double? progress;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return FitCard(
      onTap: onTap,
      variant: onTap == null
          ? FitCardVariant.outlined
          : FitCardVariant.clickable,
      padding: const EdgeInsets.all(FitSpacing.s12),
      semanticLabel: '$title${value == null ? '' : ', $value'}',
      child: Row(
        children: [
          Container(
            width: FitLayout.avatarSmall,
            height: FitLayout.avatarSmall,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: FitOpacity.selected),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: FitLayout.iconSizeCompact),
          ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall,
                      ),
                    ),
                    if (value != null) ...[
                      const SizedBox(width: FitSpacing.s8),
                      Text(
                        value!,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: accent,
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: FitSpacing.s2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall,
                  ),
                ],
                if (progress != null) ...[
                  const SizedBox(height: FitSpacing.s8),
                  FitProgressBar(value: progress!, color: accent),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: FitSpacing.s8),
            trailing!,
          ] else if (onTap != null) ...[
            const SizedBox(width: FitSpacing.s8),
            Icon(
              FitIcons.forward,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: FitLayout.iconSizeCompact,
            ),
          ],
        ],
      ),
    );
  }
}

class HomeSectionGap extends StatelessWidget {
  const HomeSectionGap({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: FitSpacing.s20);
  }
}

String homeFormatDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours <= 0) return '$minutes min';
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
}

String homeFormatNumber(num value, {int decimals = 0}) {
  final fixed = value.toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final digits = parts.first;
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  if (parts.length > 1) {
    buffer
      ..write(',')
      ..write(parts.last);
  }
  return buffer.toString();
}

String homeFormatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
