import 'package:flutter/widgets.dart';

import '../tokens/fit_duration.dart';

/// Helpers declarativos para microanimacoes curtas e previsiveis.
abstract final class FitAnimations {
  static const duration = FitDuration.normal;
  static const curve = FitDuration.curve;

  static Widget fade({
    required Widget child,
    required bool visible,
    Duration duration = FitDuration.normal,
    Curve curve = FitDuration.curve,
  }) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: duration,
      curve: curve,
      child: child,
    );
  }

  static Widget scale({
    required Widget child,
    required bool visible,
    double hiddenScale = 0.96,
    Duration duration = FitDuration.normal,
    Curve curve = FitDuration.curve,
  }) {
    return AnimatedScale(
      scale: visible ? 1 : hiddenScale,
      duration: duration,
      curve: curve,
      child: child,
    );
  }

  static Widget slide({
    required Widget child,
    required bool visible,
    Offset hiddenOffset = const Offset(0, 0.04),
    Duration duration = FitDuration.medium,
    Curve curve = FitDuration.curve,
  }) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : hiddenOffset,
      duration: duration,
      curve: curve,
      child: child,
    );
  }
}
