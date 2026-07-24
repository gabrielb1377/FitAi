import 'package:flutter/material.dart';

/// Tom semântico compartilhado por composições de domínio.
enum FitDomainTone {
  neutral,
  primary,
  info,
  ai,
  running,
  steps,
  energy,
  achievement,
  premium,
  warning,
  error,
}

/// Valor já formatado para uma métrica de apresentação.
@immutable
class FitMetricData {
  const FitMetricData({
    required this.label,
    required this.value,
    required this.icon,
    this.unit,
    this.detail,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? unit;
  final String? detail;
  final Color? color;
}

/// Ponto simples de gráfico; escala e agregação chegam prontas da aplicação.
@immutable
class FitChartPoint {
  const FitChartPoint({required this.label, required this.value});

  final String label;
  final double value;
}

/// Dados visuais de uma série de musculação.
@immutable
class FitSeriesDisplayData {
  const FitSeriesDisplayData({
    required this.index,
    required this.repetitions,
    this.weight,
    this.weightUnit = 'kg',
    this.restLabel,
    this.completed = false,
    this.current = false,
  }) : assert(index > 0),
       assert(weight == null || weight >= 0);

  final int index;
  final String repetitions;
  final double? weight;
  final String weightUnit;
  final String? restLabel;
  final bool completed;
  final bool current;
}

/// Dados visuais de um macronutriente já calculado.
@immutable
class FitMacroDisplayData {
  const FitMacroDisplayData({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    this.unit = 'g',
  }) : assert(value >= 0),
       assert(target > 0);

  final String label;
  final double value;
  final double target;
  final String unit;
  final Color color;

  double get progress => (value / target).clamp(0.0, 1.0).toDouble();
}

/// Dados visuais de conquista sem dependência do modelo de negócio.
@immutable
class FitAchievementDisplayData {
  const FitAchievementDisplayData({
    required this.title,
    required this.description,
    required this.icon,
    this.progress,
    this.unlocked = false,
  }) : assert(progress == null || (progress >= 0 && progress <= 1));

  final String title;
  final String description;
  final IconData icon;
  final double? progress;
  final bool unlocked;
}

/// Estado visual de uma semana em um plano.
@immutable
class FitPlanWeekData {
  const FitPlanWeekData({
    required this.label,
    this.completed = false,
    this.current = false,
    this.locked = false,
  }) : assert(!current || !locked);

  final String label;
  final bool completed;
  final bool current;
  final bool locked;
}
