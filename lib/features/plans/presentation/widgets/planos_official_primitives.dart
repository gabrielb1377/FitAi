import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

/// Moldura visual usada exclusivamente pelas telas oficiais de Planos.
///
/// Mantem a composicao mobile centralizada em telas largas sem transformar o
/// modulo em um dashboard desktop.
class PlanosOfficialPage extends StatelessWidget {
  const PlanosOfficialPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    this.bottomAction,
  });

  final String title;
  final Widget child;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitColors.background,
      body: SafeArea(
        bottom: bottomAction == null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth > FitBreakpoints.tablet
                ? FitBreakpoints.tablet
                : constraints.maxWidth;
            return Center(
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    FitHeader(
                      title: title,
                      subtitle: subtitle,
                      showBackButton: onBack != null,
                      onBack: onBack,
                      actions: actions,
                    ),
                    Expanded(child: child),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: bottomAction == null
          ? null
          : SafeArea(
              top: false,
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: FitBreakpoints.tablet,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      FitSpacing.s16,
                      FitSpacing.s8,
                      FitSpacing.s16,
                      FitSpacing.s16,
                    ),
                    child: bottomAction,
                  ),
                ),
              ),
            ),
    );
  }
}

/// Area de midia com a mesma geometria da arte oficial quando nao houver
/// imagem real para o plano.
class PlanosPlanMedia extends StatelessWidget {
  const PlanosPlanMedia({
    super.key,
    this.assetPath,
    this.height = FitLayout.domainChartHeight,
    this.label,
    this.compact = false,
  });

  final String? assetPath;
  final double height;
  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final image = assetPath?.trim();
    return Semantics(
      image: true,
      label: label ?? 'Imagem do plano',
      child: ClipRRect(
        borderRadius: compact ? FitRadius.mediumBorder : FitRadius.largeBorder,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: image != null && image.isNotEmpty
              ? Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _placeholder(context),
                )
              : _placeholder(context),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: FitGradients.surfaceDepth),
      child: Center(
        child: Icon(
          FitIcons.workout,
          color: Theme.of(context).colorScheme.primary,
          size: FitLayout.iconSizeLarge,
        ),
      ),
    );
  }
}

/// Metricas alinhadas de plano, treino ou biblioteca.
class PlanosMetricRow extends StatelessWidget {
  const PlanosMetricRow({super.key, required this.metrics});

  final List<PlanosMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < metrics.length; index++) ...[
          if (index > 0) const SizedBox(width: FitSpacing.s8),
          Expanded(
            child: FitMetricCard(
              label: metrics[index].label,
              value: metrics[index].value,
              icon: metrics[index].icon,
              detail: metrics[index].detail,
            ),
          ),
        ],
      ],
    );
  }
}

class PlanosMetricData {
  const PlanosMetricData({
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? detail;
}

/// Opcao de wizard com estado selecionado, icone e texto secundario.
class PlanosChoiceTile extends StatelessWidget {
  const PlanosChoiceTile({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $description',
      child: FitCard(
        variant: FitCardVariant.clickable,
        selected: selected,
        onTap: onTap,
        padding: const EdgeInsets.all(FitSpacing.s12),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
            const SizedBox(width: FitSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: FitSpacing.s2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              selected ? FitIcons.check : Icons.circle_outlined,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha navegavel para configuracoes, exercicios e itens de lista.
class PlanosNavigationRow extends StatelessWidget {
  const PlanosNavigationRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: onTap != null,
      label: title,
      child: InkWell(
        borderRadius: FitRadius.mediumBorder,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FitSpacing.s12,
            vertical: FitSpacing.s12,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: FitSpacing.s12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(color: color),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: FitSpacing.s2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    FitIcons.forward,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton especifico que preserva a densidade do dashboard de planos.
class PlanosLoadingState extends StatelessWidget {
  const PlanosLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(FitSpacing.s16),
      children: [
        const FitSkeleton(height: FitSpacing.s48, width: FitSpacing.s64),
        const SizedBox(height: FitSpacing.s16),
        const FitSkeleton(height: FitLayout.domainChartHeight),
        const SizedBox(height: FitSpacing.s16),
        const FitSkeleton(height: FitLayout.domainChartHeight),
        const SizedBox(height: FitSpacing.s16),
        const FitSkeleton(height: FitLayout.domainChartHeight),
      ],
    );
  }
}
