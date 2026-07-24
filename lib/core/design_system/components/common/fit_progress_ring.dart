import '../../../../design_system/components/fit_progress.dart';
import '../../../../design_system/tokens/fit_layout.dart';

/// Nome semântico do progresso circular oficial.
class FitProgressRing extends FitCircularProgress {
  const FitProgressRing({
    super.key,
    required double value,
    super.label,
    super.showPercentage = true,
    super.color,
    super.size = FitLayout.progressRingSize,
    super.strokeWidth = FitLayout.progressRingStroke,
  }) : super(value: value);
}
