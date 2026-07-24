/// Opacidades semânticas provisórias para estados e superfícies.
///
/// Screenshots achatados não permitem confirmar alpha; estes valores preservam
/// o comportamento anterior até validação controlada.
abstract final class FitOpacity {
  static const transparent = 0.0;
  static const subtle = 0.08;
  static const selected = 0.14;
  static const hover = 0.10;
  static const pressed = 0.16;
  static const disabled = 0.38;
  static const scrim = 0.60;

  static const contentDisabled = disabled;
  static const overlayScrim = scrim;
  static const mediaScrim = scrim;
}
