import 'settings_models.dart';

/// Converte somente para apresentacao. Valores persistidos continuam em kg,
/// centimetros, quilometros, segundos e quilocalorias.
abstract final class UnitConversion {
  static const poundsPerKilogram = 2.2046226218;
  static const kilometersPerMile = 1.609344;
  static const kilojoulesPerKilocalorie = 4.184;

  static double weightFromKilograms(double kilograms, WeightUnit unit) =>
      unit == WeightUnit.kilogram ? kilograms : kilograms * poundsPerKilogram;

  static double weightToKilograms(double value, WeightUnit unit) =>
      unit == WeightUnit.kilogram ? value : value / poundsPerKilogram;

  static double distanceFromKilometers(double kilometers, DistanceUnit unit) =>
      unit == DistanceUnit.kilometer
      ? kilometers
      : kilometers / kilometersPerMile;

  static double distanceToKilometers(double value, DistanceUnit unit) =>
      unit == DistanceUnit.kilometer ? value : value * kilometersPerMile;

  static double paceFromMinutesPerKm(double pace, PaceUnit unit) =>
      unit == PaceUnit.minutesPerKilometer ? pace : pace * kilometersPerMile;

  static double paceToMinutesPerKm(double pace, PaceUnit unit) =>
      unit == PaceUnit.minutesPerKilometer ? pace : pace / kilometersPerMile;

  static double energyFromKilocalories(double calories, EnergyUnit unit) =>
      unit == EnergyUnit.kilocalorie
      ? calories
      : calories * kilojoulesPerKilocalorie;

  static double energyToKilocalories(double value, EnergyUnit unit) =>
      unit == EnergyUnit.kilocalorie ? value : value / kilojoulesPerKilocalorie;

  static HeightPresentation heightFromCentimeters(
    double centimeters,
    HeightUnit unit,
  ) {
    if (unit == HeightUnit.centimeter) {
      return HeightPresentation(centimeters: centimeters.round());
    }
    final totalInches = (centimeters / 2.54).round();
    return HeightPresentation(
      feet: totalInches ~/ 12,
      inches: totalInches % 12,
    );
  }

  static String formatWeightKg(double kilograms, UnitSettings settings) {
    final value = weightFromKilograms(kilograms, settings.weight);
    final suffix = settings.weight == WeightUnit.kilogram ? 'kg' : 'lb';
    return '${value.toStringAsFixed(1)} $suffix';
  }

  static String formatDistanceKm(double kilometers, UnitSettings settings) {
    final value = distanceFromKilometers(kilometers, settings.distance);
    final suffix = settings.distance == DistanceUnit.kilometer ? 'km' : 'mi';
    return '${value.toStringAsFixed(2)} $suffix';
  }

  static String formatPaceMinutesPerKm(double pace, UnitSettings settings) {
    final value = paceFromMinutesPerKm(pace, settings.pace);
    final suffix = settings.pace == PaceUnit.minutesPerKilometer
        ? 'min/km'
        : 'min/mi';
    return '${value.toStringAsFixed(1)} $suffix';
  }
}

class HeightPresentation {
  const HeightPresentation({this.centimeters, this.feet, this.inches});

  final int? centimeters;
  final int? feet;
  final int? inches;

  String get label =>
      centimeters != null ? '$centimeters cm' : '$feet ft ${inches ?? 0} in';
}
