import 'package:flutter/animation.dart';

/// Duracoes e curva padrao para microinteracoes FitIA.
abstract final class FitDuration {
  static const instant = Duration.zero;
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 320);
  static const curve = Cubic(0.215, 0.61, 0.355, 1);
  static const linearCurve = Curves.linear;

  /// Alias semanticos para evitar escolher duracao por tentativa.
  static const feedback = fast;
  static const transition = normal;
  static const reveal = medium;
}
