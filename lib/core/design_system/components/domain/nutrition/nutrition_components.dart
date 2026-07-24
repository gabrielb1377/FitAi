import 'package:flutter/material.dart';

import '../../../../../design_system/components/fit_progress.dart';
import '../../../../../design_system/extensions/context_extensions.dart';
import '../../../../../design_system/tokens/fit_icons.dart';
import '../../../../../design_system/tokens/fit_layout.dart';
import '../../../../../design_system/tokens/fit_spacing.dart';
import '../../buttons/buttons.dart';
import '../../cards/cards.dart';
import '../../common/common.dart';
import '../shared/fit_domain_models.dart';
import '../shared/fit_domain_primitives.dart';

/// Resumo nutricional de um período.
class FitNutritionSummaryCard extends StatelessWidget {
  const FitNutritionSummaryCard({
    super.key,
    required this.metrics,
    this.title = 'Resumo nutricional',
    this.subtitle,
    this.progress,
    this.loading = false,
  });

  final String title;
  final String? subtitle;
  final List<FitMetricData> metrics;
  final double? progress;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: title,
      subtitle: subtitle,
      icon: FitIcons.nutrition,
      metrics: metrics,
      progress: progress,
      loading: loading,
    );
  }
}

/// Progresso circular de calorias, calculado externamente.
class FitCaloriesProgressRing extends StatelessWidget {
  const FitCaloriesProgressRing({
    super.key,
    required this.progress,
    required this.valueLabel,
    this.semanticLabel = 'Progresso de calorias',
  });

  final double progress;
  final String valueLabel;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$semanticLabel, $valueLabel',
      child: ExcludeSemantics(
        child: FitProgressRing(
          value: progress,
          label: valueLabel,
          color: context.fitColors.energy,
          size: FitLayout.domainProgressRingLarge,
          strokeWidth: FitLayout.domainProgressRingStroke,
        ),
      ),
    );
  }
}

/// Anel de progresso de um macronutriente.
class FitMacroRing extends StatelessWidget {
  const FitMacroRing({super.key, required this.data});

  final FitMacroDisplayData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FitProgressRing(
          value: data.progress,
          label: '${data.value.toStringAsFixed(0)}${data.unit}',
          color: data.color,
        ),
        const SizedBox(height: FitSpacing.s8),
        Text(
          data.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelMedium,
        ),
      ],
    );
  }
}

/// Linha quebrável de macronutrientes.
class FitMacroSummaryRow extends StatelessWidget {
  const FitMacroSummaryRow({super.key, required this.macros});

  final List<FitMacroDisplayData> macros;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: FitSpacing.s12,
      runSpacing: FitSpacing.s16,
      children: [for (final macro in macros) FitMacroRing(data: macro)],
    );
  }
}

/// Card de refeição com totais já formatados.
class FitMealCard extends StatelessWidget {
  const FitMealCard({
    super.key,
    required this.name,
    this.timeLabel,
    this.caloriesLabel,
    this.items = const [],
    this.trailing,
    this.onTap,
  });

  final String name;
  final String? timeLabel;
  final String? caloriesLabel;
  final List<Widget> items;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      title: name,
      subtitle: timeLabel,
      leading: Icon(FitIcons.food, color: context.fitColors.energy),
      trailing:
          trailing ??
          (caloriesLabel == null
              ? null
              : Text(caloriesLabel!, style: context.textTheme.labelLarge)),
      onTap: onTap,
      child: items.isEmpty
          ? Text(
              'Nenhum alimento registrado.',
              style: context.textTheme.bodySmall,
            )
          : Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  items[index],
                  if (index < items.length - 1)
                    const SizedBox(height: FitSpacing.s8),
                ],
              ],
            ),
    );
  }
}

/// Card de alimento com mídia e informações nutricionais.
class FitFoodCard extends StatelessWidget {
  const FitFoodCard({
    super.key,
    required this.name,
    this.portionLabel,
    this.caloriesLabel,
    this.media,
    this.tags = const [],
    this.onTap,
  });

  final String name;
  final String? portionLabel;
  final String? caloriesLabel;
  final Widget? media;
  final List<Widget> tags;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: name,
      subtitle: portionLabel,
      icon: FitIcons.food,
      accent: context.fitColors.energy,
      media: media,
      tags: tags,
      trailing: caloriesLabel == null
          ? null
          : Text(caloriesLabel!, style: context.textTheme.labelLarge),
      onTap: onTap,
    );
  }
}

/// Linha compacta de alimento.
class FitFoodCompactRow extends StatelessWidget {
  const FitFoodCompactRow({
    super.key,
    required this.name,
    this.portionLabel,
    this.caloriesLabel,
    this.media,
    this.onTap,
  });

  final String name;
  final String? portionLabel;
  final String? caloriesLabel;
  final Widget? media;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: name,
      subtitle: portionLabel,
      leading: media ?? Icon(FitIcons.food, color: context.fitColors.energy),
      trailing: caloriesLabel == null
          ? const Icon(FitIcons.forward)
          : Text(caloriesLabel!, style: context.textTheme.labelLarge),
      onTap: onTap,
    );
  }
}

/// Card de receita.
class FitRecipeCard extends StatelessWidget {
  const FitRecipeCard({
    super.key,
    required this.name,
    this.description,
    this.media,
    this.metrics = const [],
    this.onTap,
  });

  final String name;
  final String? description;
  final Widget? media;
  final List<FitMetricData> metrics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: name,
      subtitle: description,
      icon: FitIcons.recipe,
      accent: context.fitColors.energy,
      media: media,
      metrics: metrics,
      trailing: const Icon(FitIcons.forward),
      onTap: onTap,
    );
  }
}

/// Controle visual de hidratação com progresso externo.
class FitWaterTrackerCard extends StatelessWidget {
  const FitWaterTrackerCard({
    super.key,
    required this.valueLabel,
    required this.progress,
    this.title = 'Hidratação',
    this.quickActions = const [],
  });

  final String title;
  final String valueLabel;
  final double progress;
  final List<Widget> quickActions;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      title: title,
      leading: Icon(FitIcons.water, color: context.fitColors.chartInformation),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valueLabel, style: context.textTheme.headlineSmall),
          const SizedBox(height: FitSpacing.s12),
          FitProgress(
            value: progress,
            color: context.fitColors.chartInformation,
          ),
          if (quickActions.isNotEmpty) ...[
            const SizedBox(height: FitSpacing.s12),
            Wrap(
              spacing: FitSpacing.s8,
              runSpacing: FitSpacing.s8,
              children: quickActions,
            ),
          ],
        ],
      ),
    );
  }
}

/// Botão compacto para adicionar uma quantidade de água.
class FitWaterQuickAddButton extends StatelessWidget {
  const FitWaterQuickAddButton({
    super.key,
    required this.label,
    this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FitOutlinedButton(
      label: label,
      icon: FitIcons.add,
      onPressed: onPressed,
      enabled: enabled,
      size: FitButtonSize.small,
    );
  }
}

/// Resumo alimentar diário.
class FitDailyNutritionCard extends StatelessWidget {
  const FitDailyNutritionCard({
    super.key,
    required this.caloriesLabel,
    required this.progress,
    this.title = 'Hoje',
    this.macros = const [],
  });

  final String title;
  final String caloriesLabel;
  final double progress;
  final List<FitMacroDisplayData> macros;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      title: title,
      child: Column(
        children: [
          FitCaloriesProgressRing(
            progress: progress,
            valueLabel: caloriesLabel,
          ),
          if (macros.isNotEmpty) ...[
            const SizedBox(height: FitSpacing.s16),
            FitMacroSummaryRow(macros: macros),
          ],
        ],
      ),
    );
  }
}

/// Badge de pontuação nutricional já calculada.
class FitNutritionScoreBadge extends StatelessWidget {
  const FitNutritionScoreBadge({
    super.key,
    required this.label,
    this.positive = true,
  });

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return FitDomainStatusBadge(
      label: label,
      tone: positive ? FitDomainTone.primary : FitDomainTone.warning,
      icon: FitIcons.nutrition,
    );
  }
}

/// Timer visual de jejum controlado por estado externo.
class FitFastingTimerCard extends StatelessWidget {
  const FitFastingTimerCard({
    super.key,
    required this.durationLabel,
    required this.progress,
    this.title = 'Jejum',
    this.active = false,
    this.onToggle,
  });

  final String title;
  final String durationLabel;
  final double progress;
  final bool active;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      title: title,
      leading: Icon(FitIcons.timer, color: context.fitColors.energy),
      child: Column(
        children: [
          FitProgressRing(
            value: progress,
            label: durationLabel,
            color: context.fitColors.energy,
          ),
          const SizedBox(height: FitSpacing.s12),
          FitOutlinedButton(
            label: active ? 'Encerrar' : 'Iniciar',
            icon: active ? FitIcons.stop : FitIcons.play,
            onPressed: onToggle,
          ),
        ],
      ),
    );
  }
}

/// Item de lista de compras.
class FitShoppingListItem extends StatelessWidget {
  const FitShoppingListItem({
    super.key,
    required this.name,
    required this.checked,
    this.quantityLabel,
    this.onChanged,
  });

  final String name;
  final String? quantityLabel;
  final bool checked;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: name,
      subtitle: quantityLabel,
      leading: Checkbox(
        value: checked,
        onChanged: onChanged == null
            ? null
            : (value) => onChanged!(value ?? false),
      ),
      semanticLabel: '$name, ${checked ? 'marcado' : 'não marcado'}',
    );
  }
}

/// Insight nutricional de caráter apenas apresentacional.
class FitNutritionInsightCard extends StatelessWidget {
  const FitNutritionInsightCard({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : assert((actionLabel == null) == (onAction == null));

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return FitInfoCard(
      title: title,
      description: message,
      icon: FitIcons.nutrition,
      tone: FitInfoCardTone.info,
      action: onAction == null
          ? null
          : FitGhostButton(label: actionLabel!, onPressed: onAction),
    );
  }
}

/// Meta nutricional com progresso externo.
class FitNutritionGoalCard extends StatelessWidget {
  const FitNutritionGoalCard({
    super.key,
    required this.title,
    required this.value,
    required this.progress,
    this.description,
  });

  final String title;
  final String value;
  final double progress;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return FitProgressCard(
      title: title,
      value: value,
      progress: progress,
      icon: FitIcons.goal,
      color: context.fitColors.energy,
      description: description,
    );
  }
}

/// Linha de micronutriente com valor e progresso externos.
class FitMicronutrientRow extends StatelessWidget {
  const FitMicronutrientRow({
    super.key,
    required this.name,
    required this.valueLabel,
    required this.progress,
  });

  final String name;
  final String valueLabel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FitListTile(
          title: name,
          trailing: Text(valueLabel, style: context.textTheme.labelLarge),
          contentPadding: EdgeInsets.zero,
        ),
        FitProgress(value: progress, color: context.fitColors.energy),
      ],
    );
  }
}

/// Placeholder visual para uma futura integração de código de barras.
class FitBarcodeScannerPlaceholder extends StatelessWidget {
  const FitBarcodeScannerPlaceholder({
    super.key,
    this.title = 'Ler código de barras',
    this.description = 'O scanner será fornecido pela aplicação.',
    this.onAction,
  });

  final String title;
  final String description;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _ScannerPlaceholder(
      title: title,
      description: description,
      icon: FitIcons.scanner,
      onAction: onAction,
    );
  }
}

/// Placeholder visual para uma futura leitura de alimento por foto.
class FitFoodPhotoScannerPlaceholder extends StatelessWidget {
  const FitFoodPhotoScannerPlaceholder({
    super.key,
    this.title = 'Analisar alimento',
    this.description = 'A câmera será fornecida pela aplicação.',
    this.onAction,
  });

  final String title;
  final String description;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _ScannerPlaceholder(
      title: title,
      description: description,
      icon: FitIcons.food,
      onAction: onAction,
    );
  }
}

class _ScannerPlaceholder extends StatelessWidget {
  const _ScannerPlaceholder({
    required this.title,
    required this.description,
    required this.icon,
    this.onAction,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      child: Column(
        children: [
          Icon(
            icon,
            size: FitLayout.iconSizeState,
            color: context.fitColors.energy,
          ),
          const SizedBox(height: FitSpacing.s12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge,
          ),
          const SizedBox(height: FitSpacing.s8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium,
          ),
          if (onAction != null) ...[
            const SizedBox(height: FitSpacing.s16),
            FitOutlinedButton(label: 'Abrir', icon: icon, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
