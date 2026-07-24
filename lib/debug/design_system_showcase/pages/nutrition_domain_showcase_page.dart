import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../domain_showcase_scaffold.dart';

/// Catálogo visual dos componentes do domínio Nutrição.
class NutritionDomainShowcasePage extends StatelessWidget {
  const NutritionDomainShowcasePage({super.key});

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    final macros = [
      FitMacroDisplayData(
        label: 'Proteínas',
        value: 112,
        target: 160,
        color: context.colors.primary,
      ),
      FitMacroDisplayData(
        label: 'Carboidratos',
        value: 180,
        target: 260,
        color: context.fitColors.chartInformation,
      ),
      FitMacroDisplayData(
        label: 'Gorduras',
        value: 48,
        target: 70,
        color: context.fitColors.energy,
      ),
    ];
    return DomainShowcaseScaffold(
      title: 'Nutrição',
      children: [
        const FitNutritionSummaryCard(
          metrics: [
            FitMetricData(
              label: 'Calorias',
              value: '1.820',
              icon: FitIcons.calories,
            ),
            FitMetricData(label: 'Refeições', value: '4', icon: FitIcons.food),
          ],
          progress: .72,
        ),
        const FitCaloriesProgressRing(progress: .72, valueLabel: '1.820 kcal'),
        FitMacroRing(data: macros.first),
        FitMacroSummaryRow(macros: macros),
        const FitMealCard(
          name: 'Café da manhã',
          timeLabel: '08:00',
          caloriesLabel: '420 kcal',
          items: [
            FitFoodCompactRow(
              name: 'Ovos mexidos',
              portionLabel: '3 unidades',
              caloriesLabel: '210 kcal',
            ),
          ],
          onTap: _noop,
        ),
        const FitFoodCard(
          name: 'Frango grelhado',
          portionLabel: '150 g',
          caloriesLabel: '248 kcal',
          onTap: _noop,
        ),
        const FitFoodCompactRow(
          name: 'Arroz integral',
          portionLabel: '120 g',
          caloriesLabel: '148 kcal',
          onTap: _noop,
        ),
        const FitRecipeCard(
          name: 'Bowl proteico',
          description: 'Frango, arroz e vegetais',
          metrics: [
            FitMetricData(
              label: 'Tempo',
              value: '25',
              unit: 'min',
              icon: FitIcons.time,
            ),
          ],
          onTap: _noop,
        ),
        const FitWaterTrackerCard(
          valueLabel: '1,8 de 3,0 L',
          progress: .6,
          quickActions: [
            FitWaterQuickAddButton(label: '+250 ml', onPressed: _noop),
            FitWaterQuickAddButton(label: '+500 ml', onPressed: _noop),
          ],
        ),
        const FitWaterQuickAddButton(label: '+250 ml', onPressed: _noop),
        FitDailyNutritionCard(
          caloriesLabel: '1.820 kcal',
          progress: .72,
          macros: macros,
        ),
        const FitNutritionScoreBadge(label: 'Excelente'),
        const FitFastingTimerCard(
          durationLabel: '12:18',
          progress: .76,
          active: true,
          onToggle: _noop,
        ),
        const FitShoppingListItem(
          name: 'Peito de frango',
          quantityLabel: '1 kg',
          checked: false,
          onChanged: _ignoreNullableBool,
        ),
        const FitNutritionInsightCard(
          title: 'Consistência',
          message: 'A ingestão de proteínas está próxima da sua meta.',
          actionLabel: 'Ver detalhes',
          onAction: _noop,
        ),
        const FitNutritionGoalCard(
          title: 'Meta de proteínas',
          value: '112 / 160 g',
          progress: .7,
        ),
        const FitMicronutrientRow(
          name: 'Ferro',
          valueLabel: '12 / 18 mg',
          progress: .66,
        ),
        const FitBarcodeScannerPlaceholder(onAction: _noop),
        const FitFoodPhotoScannerPlaceholder(onAction: _noop),
        const FitNutritionSummaryCard(metrics: [], loading: true),
        const DomainShowcaseStates(emptyTitle: 'Sem dados nutricionais'),
      ],
    );
  }
}

void _ignoreNullableBool(bool _) {}
