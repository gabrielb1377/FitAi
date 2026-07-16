import 'fit_metric_card.dart';

/// Alias semantico para uma metrica que precisa de superficie propria.
class FitStatCard extends FitMetricCard {
  const FitStatCard({
    super.key,
    required super.label,
    required super.value,
    required super.icon,
    super.detail,
    super.color,
    super.onTap,
  });
}
