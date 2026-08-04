import '../../progression/progression.dart';

/// Fonte local que contribui para a projecao do Perfil.
enum ProfileDataSource {
  profile,
  plans,
  library,
  activities,
  xp,
  goals,
  achievements,
  progression,
  preferences,
}

/// Disponibilidade de uma fonte que ainda nao possui dados locais suficientes.
enum ProfileDataAvailability { available, unavailable }

/// Permissoes que fazem parte das preferencias observaveis do usuario.
enum UserPermission { activity, location, notifications, healthConnect }

/// Estado independente de plataforma para uma permissao do usuario.
enum UserPermissionStatus { pending, granted, denied, unavailable }

/// Dados pessoais informados pelo usuario, sem valores de demonstracao.
class UserProfile {
  const UserProfile({
    this.name,
    this.avatarPath,
    this.weightKg,
    this.heightCm,
    this.ageYears,
  });

  final String? name;
  final String? avatarPath;
  final double? weightKg;
  final double? heightCm;
  final int? ageYears;

  bool get hasIdentity => name != null || avatarPath != null;

  factory UserProfile.fromLocalValues(Map<String, String> values) {
    return UserProfile(
      name: _nonBlank(values['nome']),
      weightKg: _number(values['peso']),
      heightCm: _heightInCentimeters(values['altura']),
      ageYears: _positiveInteger(values['idade']),
    );
  }

  static String? _nonBlank(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static double? _number(String? value) {
    final match = RegExp(r'[-+]?\d+(?:[\.,]\d+)?').firstMatch(value ?? '');
    final number = double.tryParse(match?.group(0)?.replaceAll(',', '.') ?? '');
    return number == null || number <= 0 ? null : number;
  }

  static double? _heightInCentimeters(String? value) {
    final number = _number(value);
    if (number == null) return null;
    return number <= 3 ? number * 100 : number;
  }

  static int? _positiveInteger(String? value) {
    final number = _number(value)?.round();
    return number == null || number <= 0 ? null : number;
  }
}

/// Metricas agregadas por leitura das fontes donas dos dados.
class UserStats {
  const UserStats({
    required this.activeDays,
    required this.totalRuns,
    required this.totalSteps,
    required this.completedWorkouts,
    required this.favoriteExercises,
    required this.favoriteExerciseIds,
    this.completedPlans,
    this.lastWorkoutAt,
    this.lastWorkoutName,
    this.lastRunAt,
    this.lastRunDistanceKm,
    this.lastStepsAt,
    this.latestSteps,
    this.dailyStepsGoal,
    this.usingLegacyWorkoutHistory = false,
  });

  final int activeDays;
  final int totalRuns;
  final int totalSteps;
  final int completedWorkouts;
  final int? completedPlans;
  final int favoriteExercises;
  final Set<String> favoriteExerciseIds;
  final DateTime? lastWorkoutAt;
  final String? lastWorkoutName;
  final DateTime? lastRunAt;
  final double? lastRunDistanceKm;
  final DateTime? lastStepsAt;
  final int? latestSteps;
  final int? dailyStepsGoal;
  final bool usingLegacyWorkoutHistory;
}

/// Preferencias e permissoes observaveis sem assumir configuracoes ausentes.
class UserPreferences {
  const UserPreferences({
    this.themeMode,
    this.languageCode,
    this.notificationsEnabled,
    this.permissions = const {},
    this.availability = ProfileDataAvailability.available,
  });

  const UserPreferences.unavailable()
    : themeMode = null,
      languageCode = null,
      notificationsEnabled = null,
      permissions = const {},
      availability = ProfileDataAvailability.unavailable;

  final String? themeMode;
  final String? languageCode;
  final bool? notificationsEnabled;
  final Map<UserPermission, UserPermissionStatus> permissions;
  final ProfileDataAvailability availability;
}

/// Falha isolada de uma fonte local que nao impede a abertura parcial do Perfil.
class ProfileLoadIssue {
  const ProfileLoadIssue({required this.source, required this.error});

  final ProfileDataSource source;
  final Object error;
}

/// Projecao de leitura do Perfil para controllers e telas futuras.
class ProfileSnapshot {
  const ProfileSnapshot({
    required this.profile,
    required this.stats,
    required this.progression,
    required this.preferences,
    this.issues = const [],
  });

  final UserProfile profile;
  final UserStats stats;
  final ProgressionSnapshot progression;
  final UserPreferences preferences;
  final List<ProfileLoadIssue> issues;

  bool get hasPartialData => issues.isNotEmpty;
}
