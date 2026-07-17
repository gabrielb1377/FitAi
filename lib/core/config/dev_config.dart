import 'package:flutter/foundation.dart';

/// Configuracoes locais para acelerar demonstracoes e testes durante o debug.
/// Todas as flags sao `false` em builds profile e release.
abstract final class DevConfig {
  static const bool enabled = kDebugMode;
  static const bool bypassLogin = kDebugMode;
  static const bool fakeUser = kDebugMode;
  static const bool fakePremium = kDebugMode;
  static const bool fakeCoach = kDebugMode;
  static const bool fakeWorkout = kDebugMode;
  static const bool fakeSteps = kDebugMode;
  static const bool fakeRunning = kDebugMode;
  static const bool fakeNutrition = kDebugMode;

  /// Mantenha desativado por padrao para aproximar o debug da experiencia real.
  static const bool showDevBanner = false;
}
