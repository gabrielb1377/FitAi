import 'package:flutter/animation.dart';

/// Tokens provisórios de duração e curva para microinterações.
///
/// O DS3 confirma os papéis, mas não os valores temporais. Esta escala preserva
/// o sistema anterior até existir protótipo ou medição aprovada.
abstract final class FitDuration {
  static const instant = Duration.zero;
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 320);
  static const standardCurve = Cubic(0.215, 0.61, 0.355, 1);
  static const enterCurve = standardCurve;
  static const exitCurve = standardCurve;
  static const curve = standardCurve;
  static const linearCurve = Curves.linear;

  /// Aliases semânticos para evitar escolher duração por tentativa.
  static const feedback = fast;
  static const transition = normal;
  static const reveal = medium;
  static const pageTransition = normal;
  static const bottomSheet = medium;
  static const fade = normal;
  static const scale = fast;
  static const pressed = fast;
  static const progress = medium;
  static const snackBar = Duration(seconds: 4);

  /// Compatibilidade com `AppMotion`; não usar em APIs novas.
  static const legacyAppFast = Duration(milliseconds: 160);
  static const legacyAppNormal = medium;
  static const legacyAppSlow = slow;

  static const positiveDurations = <Duration>[fast, normal, medium, slow];
}
