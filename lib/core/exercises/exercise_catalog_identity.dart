import '../../models/exercicio_model.dart';
import 'exercise_identity.dart';

/// Classification of an identifier at a catalog boundary.
enum ExerciseCatalogIdKind { canonical, legacy, derived, invalid, missing }

/// Searchable identity metadata projected from the existing exercise catalog.
///
/// This object intentionally does not persist another catalog. The source
/// exercise remains [ExercicioModel], so plans, sessions and history keep the
/// IDs they already own.
class ExerciseCatalogEntry {
  const ExerciseCatalogEntry({
    required this.exercise,
    required this.aliases,
    required this.movementPattern,
  });

  final ExercicioModel exercise;
  final Set<String> aliases;
  final ExerciseMovementPattern movementPattern;

  String get canonicalId => exercise.id.trim();
  String get canonicalName => exercise.nome.trim();

  /// Stable key reserved for the media phase. It is not a URL or a mapping.
  String get mediaKey => 'exercise/$canonicalId';
}

enum ExerciseMovementPattern {
  horizontalPush,
  horizontalPull,
  verticalPush,
  verticalPull,
  squat,
  hinge,
  lunge,
  carry,
  rotation,
  isolation,
  unknown,
}

class ExerciseCatalogResolution {
  const ExerciseCatalogResolution({
    required this.entry,
    required this.kind,
    required this.matchedValue,
  });

  final ExerciseCatalogEntry entry;
  final ExerciseCatalogIdKind kind;
  final String matchedValue;
}

/// Canonical, deterministic lookup over the bundled exercise catalog.
///
/// Aliases only resolve when they identify one catalog entry. Ambiguous names
/// intentionally return null and must be reviewed instead of silently merging
/// history or prescriptions.
class ExerciseCatalogIdentity {
  ExerciseCatalogIdentity(
    Iterable<ExercicioModel> exercises, {
    Map<String, String> legacyIdRedirects = defaultLegacyIdRedirects,
  }) : _legacyIdRedirects = Map.unmodifiable(legacyIdRedirects) {
    final aliasesById = <String, Set<String>>{};
    final raw = exercises.toList(growable: false);
    for (final exercise in raw) {
      final id = exercise.id.trim();
      if (id.isEmpty || _byId.containsKey(id)) continue;
      aliasesById[id] = <String>{exercise.nome, ...exercise.tags}
          .map(ExerciseIdentity.normalizeName)
          .where((item) => item.isNotEmpty)
          .toSet();
    }

    for (final entry in _verifiedAliases.entries) {
      aliasesById[entry.value]?.add(ExerciseIdentity.normalizeName(entry.key));
    }

    for (final exercise in raw) {
      final id = exercise.id.trim();
      if (id.isEmpty || _byId.containsKey(id)) continue;
      final entry = ExerciseCatalogEntry(
        exercise: exercise,
        aliases: Set.unmodifiable(aliasesById[id] ?? const <String>{}),
        movementPattern: ExerciseTaxonomy.movementFor(exercise),
      );
      _byId[id] = entry;
      for (final alias in entry.aliases) {
        _byAlias.putIfAbsent(alias, () => <ExerciseCatalogEntry>[]).add(entry);
      }
    }

    // Catalog tags support discovery and may be shared by multiple entries.
    // Verified aliases are editorial identity decisions, so they are resolved
    // before the generic tag index and only when their target ID exists.
    for (final entry in _verifiedAliases.entries) {
      final alias = ExerciseIdentity.normalizeName(entry.key);
      final target = _byId[entry.value];
      if (alias.isNotEmpty && target != null) {
        _byVerifiedAlias[alias] = target;
      }
    }
  }

  /// Verified legacy values observed in historical fixtures and routes.
  ///
  /// Do not add a redirect when the source name is ambiguous. For example,
  /// `agachamento-livre` exists in more than one catalog category and must be
  /// resolved using its preserved snapshot until an editorial decision exists.
  static const defaultLegacyIdRedirects = <String, String>{
    'supino-reto': 'peito_001',
    'remada-curvada': 'costas_002',
    'triceps-corda': 'triceps_007',
  };

  static const _verifiedAliases = <String, String>{
    'supino reto': 'peito_001',
    'bench press': 'peito_001',
    'barbell bench press': 'peito_001',
    'remada curvada': 'costas_002',
    'barbell row': 'costas_002',
    'pull up': 'costas_003',
    'pull-up': 'costas_003',
    'triceps corda': 'triceps_007',
    // The backend's reviewed fallback uses this generic name for the
    // conventional dumbbell movement, never the cable or band variations.
    'elevacao lateral': 'ombros_003',
  };

  final Map<String, ExerciseCatalogEntry> _byId =
      <String, ExerciseCatalogEntry>{};
  final Map<String, List<ExerciseCatalogEntry>> _byAlias =
      <String, List<ExerciseCatalogEntry>>{};
  final Map<String, ExerciseCatalogEntry> _byVerifiedAlias =
      <String, ExerciseCatalogEntry>{};
  final Map<String, String> _legacyIdRedirects;

  List<ExerciseCatalogEntry> get entries =>
      List.unmodifiable(_byId.values.toList(growable: false));

  int get ambiguousAliasCount =>
      _byAlias.values.where((entries) => entries.length > 1).length;

  int get uniqueAliasCount =>
      _byAlias.values.where((entries) => entries.length == 1).length;

  Set<String> aliasesFor(ExercicioModel exercise) =>
      _byId[exercise.id.trim()]?.aliases ?? const <String>{};

  ExerciseCatalogIdKind classifyId(
    String? value, {
    Iterable<String> derivedIds = const <String>[],
  }) {
    final id = value?.trim() ?? '';
    if (id.isEmpty) return ExerciseCatalogIdKind.missing;
    if (_byId.containsKey(id)) return ExerciseCatalogIdKind.canonical;
    if (_legacyIdRedirects.containsKey(id)) return ExerciseCatalogIdKind.legacy;
    if (derivedIds.map((item) => item.trim()).contains(id)) {
      return ExerciseCatalogIdKind.derived;
    }
    return ExerciseCatalogIdKind.invalid;
  }

  ExerciseCatalogResolution? resolve({
    String? exerciseId,
    String? nameOrAlias,
  }) {
    final id = exerciseId?.trim() ?? '';
    final direct = _byId[id];
    if (direct != null) {
      return ExerciseCatalogResolution(
        entry: direct,
        kind: ExerciseCatalogIdKind.canonical,
        matchedValue: id,
      );
    }

    final redirected = _legacyIdRedirects[id];
    final legacy = redirected == null ? null : _byId[redirected];
    if (legacy != null) {
      return ExerciseCatalogResolution(
        entry: legacy,
        kind: ExerciseCatalogIdKind.legacy,
        matchedValue: id,
      );
    }

    final alias = ExerciseIdentity.normalizeName(nameOrAlias ?? '');
    final verifiedAlias = _byVerifiedAlias[alias];
    if (verifiedAlias != null) {
      return ExerciseCatalogResolution(
        entry: verifiedAlias,
        kind: ExerciseCatalogIdKind.canonical,
        matchedValue: alias,
      );
    }
    final matches = _byAlias[alias];
    if (matches == null || matches.length != 1) return null;
    return ExerciseCatalogResolution(
      entry: matches.single,
      kind: ExerciseCatalogIdKind.canonical,
      matchedValue: alias,
    );
  }
}

/// Normalization rules used by catalog search and future editorial metadata.
///
/// Unknown values stay explicit instead of being forced into an incorrect
/// anatomical or movement bucket.
abstract final class ExerciseTaxonomy {
  static String muscleKey(String value) {
    final normalized = ExerciseIdentity.normalizeName(value);
    return switch (normalized) {
      'peito' || 'peitoral' || 'peitoral maior' => 'peitoral_maior',
      'gluteos' || 'gluteo maximo' => 'gluteo_maximo',
      'posterior' || 'posteriores' || 'isquiotibiais' => 'isquiotibiais',
      'abdomen' || 'core' => 'core',
      'biceps' || 'biceps braquial' => 'biceps_braquial',
      'triceps' || 'triceps braquial' => 'triceps_braquial',
      'dorsal' ||
      'grande dorsal' ||
      'latissimo do dorso' => 'latissimo_do_dorso',
      _ => normalized,
    };
  }

  static String equipmentKey(String value) {
    final normalized = ExerciseIdentity.normalizeName(value);
    return switch (normalized) {
      'barra' || 'barra reta' || 'ez bar' || 'barra ez' => 'barbell',
      'halter' || 'halteres' => 'dumbbell',
      'cabo' || 'cabos' || 'polia' || 'polia alta' || 'polia baixa' => 'cable',
      'peso corporal' || 'corpo livre' => 'bodyweight',
      'maquina' || 'smith machine' || 'maquina smith' => 'machine',
      'elastico' ||
      'faixa elastica' ||
      'elastico de resistencia' => 'resistance_band',
      _ => normalized,
    };
  }

  static ExerciseMovementPattern movementFor(ExercicioModel exercise) {
    final text = ExerciseIdentity.normalizeName(
      [exercise.nome, ...exercise.tags].join(' '),
    );
    if (RegExp(r'supino|flexao|chest press').hasMatch(text)) {
      return ExerciseMovementPattern.horizontalPush;
    }
    if (RegExp(r'remada').hasMatch(text)) {
      return ExerciseMovementPattern.horizontalPull;
    }
    if (RegExp(r'desenvolvimento|shoulder press').hasMatch(text)) {
      return ExerciseMovementPattern.verticalPush;
    }
    if (RegExp(r'puxada|barra fixa|pull up|pulldown').hasMatch(text)) {
      return ExerciseMovementPattern.verticalPull;
    }
    if (RegExp(r'agachamento|leg press').hasMatch(text)) {
      return ExerciseMovementPattern.squat;
    }
    if (RegExp(r'terra|stiff|romeno|good morning').hasMatch(text)) {
      return ExerciseMovementPattern.hinge;
    }
    if (RegExp(r'afundo|lunge|passada').hasMatch(text)) {
      return ExerciseMovementPattern.lunge;
    }
    if (RegExp(r'rosca|extensora|flexora|elevacao|triceps').hasMatch(text)) {
      return ExerciseMovementPattern.isolation;
    }
    return ExerciseMovementPattern.unknown;
  }
}
