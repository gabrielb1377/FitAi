import '../../../../design_system/components/fit_metric.dart';

/// Nome semântico de uma estatística compacta.
class FitStatistic extends FitMetric {
  const FitStatistic({
    super.key,
    required super.label,
    required super.icon,
    super.value,
    super.detail,
    super.unit,
    super.trend,
    super.color,
    super.alignment,
    super.isLoading,
    super.unavailable,
  });
}
