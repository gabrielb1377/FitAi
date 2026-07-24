import 'fit_shadows.dart';

/// Camadas semânticas do FitIA.
///
/// Os aliases combinam com superfícies e bordas no tema; as listas abaixo não
/// devem ser usadas isoladamente para comunicar hierarquia.
abstract final class FitElevation {
  static const level0 = FitShadows.none;
  static const level1 = FitShadows.low;
  static const level2 = FitShadows.medium;
  static const level3 = FitShadows.high;

  static const background = level0;
  static const surface = level0;
  static const card = level1;
  static const cardRaised = level2;
  static const floatingControl = level2;
  static const bottomSheet = level3;
  static const dialog = level3;
  static const overlay = level3;

  static const materialBackground = 0.0;
  static const materialSurface = 0.0;
  static const materialCard = 0.0;
  static const materialCardRaised = 1.0;
  static const materialFloatingControl = 2.0;
  static const materialBottomSheet = 2.0;
  static const materialDialog = 3.0;
  static const materialOverlay = 3.0;
}
