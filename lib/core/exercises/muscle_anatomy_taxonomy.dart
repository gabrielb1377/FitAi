import '../../models/exercicio_model.dart';
import 'exercise_identity.dart';

/// Stable, fitness-oriented muscle regions used by the anatomy renderer.
enum MuscleAnatomyView { front, back }

enum MuscleAnatomyRole { primary, secondary }

enum MuscleMappingStatus { mapped, partial, unmapped, ambiguous }

class MuscleRegion {
  const MuscleRegion({
    required this.id,
    required this.label,
    required this.views,
  });

  final String id;
  final String label;
  final Set<MuscleAnatomyView> views;
}

class MuscleLabelResolution {
  const MuscleLabelResolution.mapped(this.regionIds) : ambiguous = false;

  const MuscleLabelResolution.ambiguous()
    : regionIds = const [],
      ambiguous = true;

  final List<String> regionIds;
  final bool ambiguous;
}

class ExerciseMuscleAnatomy {
  const ExerciseMuscleAnatomy({
    required this.exerciseId,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.unmappedLabels,
    required this.ambiguousLabels,
    required this.overlappingMuscleIds,
    required this.status,
  });

  final String exerciseId;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> unmappedLabels;
  final List<String> ambiguousLabels;
  final List<String> overlappingMuscleIds;
  final MuscleMappingStatus status;

  bool get hasRenderableRegions =>
      primaryMuscles.isNotEmpty || secondaryMuscles.isNotEmpty;

  bool get isVisualSafe =>
      primaryMuscles.isNotEmpty &&
      primaryMuscles.length <= 3 &&
      primaryMuscles.length + secondaryMuscles.length <= 5 &&
      ambiguousLabels.isEmpty &&
      overlappingMuscleIds.isEmpty;
}

/// Versioned catalog taxonomy. Labels are normalized only for exact lookup;
/// unknown or overly broad terms are never inferred from exercise names.
abstract final class MuscleAnatomyTaxonomy {
  static const version = '1.0.0';

  static const regions = <MuscleRegion>[
    MuscleRegion(
      id: 'chest',
      label: 'Peitoral',
      views: {MuscleAnatomyView.front},
    ),
    MuscleRegion(
      id: 'upper_chest',
      label: 'Peitoral superior',
      views: {MuscleAnatomyView.front},
    ),
    MuscleRegion(
      id: 'lower_chest',
      label: 'Peitoral inferior',
      views: {MuscleAnatomyView.front},
    ),
    MuscleRegion(
      id: 'serratus',
      label: 'Serrátil anterior',
      views: {MuscleAnatomyView.front},
    ),
    MuscleRegion(
      id: 'front_deltoid',
      label: 'Deltoide anterior',
      views: {MuscleAnatomyView.front},
    ),
    MuscleRegion(
      id: 'side_deltoid',
      label: 'Deltoide lateral',
      views: {MuscleAnatomyView.front, MuscleAnatomyView.back},
    ),
    MuscleRegion(
      id: 'rear_deltoid',
      label: 'Deltoide posterior',
      views: {MuscleAnatomyView.back},
    ),
    MuscleRegion(
      id: 'biceps',
      label: 'Bíceps',
      views: {MuscleAnatomyView.front},
    ),
    MuscleRegion(
      id: 'brachialis',
      label: 'Braquial',
      views: {MuscleAnatomyView.front},
    ),
    MuscleRegion(
      id: 'triceps',
      label: 'Tríceps',
      views: {MuscleAnatomyView.back},
    ),
    MuscleRegion(
      id: 'forearms',
      label: 'Antebraços',
      views: {MuscleAnatomyView.front, MuscleAnatomyView.back},
    ),
    MuscleRegion(id: 'abs', label: 'Abdômen', views: {MuscleAnatomyView.front}),
    MuscleRegion(
      id: 'obliques',
      label: 'Oblíquos',
      views: {MuscleAnatomyView.front, MuscleAnatomyView.back},
    ),
    MuscleRegion(
      id: 'hip_flexors',
      label: 'Flexores do quadril',
      views: {MuscleAnatomyView.front},
    ),
    MuscleRegion(
      id: 'adductors',
      label: 'Adutores',
      views: {MuscleAnatomyView.front},
    ),
    MuscleRegion(
      id: 'quadriceps',
      label: 'Quadríceps',
      views: {MuscleAnatomyView.front},
    ),
    MuscleRegion(
      id: 'calves',
      label: 'Panturrilhas',
      views: {MuscleAnatomyView.front, MuscleAnatomyView.back},
    ),
    MuscleRegion(
      id: 'traps',
      label: 'Trapézio',
      views: {MuscleAnatomyView.back},
    ),
    MuscleRegion(
      id: 'upper_back',
      label: 'Costas superiores',
      views: {MuscleAnatomyView.back},
    ),
    MuscleRegion(id: 'lats', label: 'Dorsais', views: {MuscleAnatomyView.back}),
    MuscleRegion(
      id: 'lower_back',
      label: 'Lombar',
      views: {MuscleAnatomyView.back},
    ),
    MuscleRegion(
      id: 'glutes',
      label: 'Glúteos',
      views: {MuscleAnatomyView.back},
    ),
    MuscleRegion(
      id: 'hamstrings',
      label: 'Posteriores de coxa',
      views: {MuscleAnatomyView.back},
    ),
    MuscleRegion(
      id: 'neck',
      label: 'Pescoço',
      views: {MuscleAnatomyView.front, MuscleAnatomyView.back},
    ),
    MuscleRegion(
      id: 'rotator_cuff',
      label: 'Manguito rotador',
      views: {MuscleAnatomyView.back},
    ),
    MuscleRegion(
      id: 'tibialis',
      label: 'Tibial anterior',
      views: {MuscleAnatomyView.front},
    ),
    MuscleRegion(
      id: 'spinal_erectors',
      label: 'Eretores da coluna',
      views: {MuscleAnatomyView.back},
    ),
    MuscleRegion(
      id: 'hands',
      label: 'Mãos',
      views: {MuscleAnatomyView.front, MuscleAnatomyView.back},
    ),
  ];

  static final Map<String, MuscleRegion> byId = Map.unmodifiable({
    for (final region in regions) region.id: region,
  });

  static final Map<String, MuscleLabelResolution> _labels = _buildLabels();

  static MuscleLabelResolution? resolveLabel(String rawLabel) =>
      _labels[ExerciseIdentity.normalizeName(rawLabel)];

  static ExerciseMuscleAnatomy mapExercise(ExercicioModel exercise) {
    final primary = <String>{};
    final secondary = <String>{};
    final unmapped = <String>[];
    final ambiguous = <String>[];
    final overlaps = <String>[];

    void mapLabels(Iterable<String> labels, Set<String> target) {
      for (final label in labels) {
        final trimmed = label.trim();
        if (trimmed.isEmpty) continue;
        final resolution = resolveLabel(trimmed);
        if (resolution == null) {
          unmapped.add(trimmed);
        } else if (resolution.ambiguous) {
          ambiguous.add(trimmed);
        } else {
          target.addAll(resolution.regionIds);
        }
      }
    }

    mapLabels(exercise.musculos, primary);
    mapLabels(exercise.musculosSecundarios, secondary);
    for (final id in primary.intersection(secondary)) {
      overlaps.add(id);
      secondary.remove(id);
    }

    final resolvedCount = primary.length + secondary.length;
    final unsafeSize = primary.length > 3 || resolvedCount > 5;
    final hasIssue =
        unmapped.isNotEmpty ||
        ambiguous.isNotEmpty ||
        overlaps.isNotEmpty ||
        unsafeSize;
    final status = ambiguous.isNotEmpty || overlaps.isNotEmpty || unsafeSize
        ? MuscleMappingStatus.ambiguous
        : resolvedCount == 0
        ? MuscleMappingStatus.unmapped
        : hasIssue
        ? MuscleMappingStatus.partial
        : primary.isEmpty
        ? MuscleMappingStatus.ambiguous
        : MuscleMappingStatus.mapped;

    return ExerciseMuscleAnatomy(
      exerciseId: exercise.id,
      primaryMuscles: primary.toList(growable: false),
      secondaryMuscles: secondary.toList(growable: false),
      unmappedLabels: unmapped.toSet().toList(growable: false),
      ambiguousLabels: ambiguous.toSet().toList(growable: false),
      overlappingMuscleIds: overlaps.toList(growable: false),
      status: status,
    );
  }

  static Map<String, MuscleLabelResolution> _buildLabels() {
    final labels = <String, MuscleLabelResolution>{};

    void register(String value, MuscleLabelResolution resolution) {
      final key = ExerciseIdentity.normalizeName(value);
      final existing = labels[key];
      if (existing == null) {
        labels[key] = resolution;
        return;
      }
      if (existing.ambiguous || resolution.ambiguous) {
        labels[key] = const MuscleLabelResolution.ambiguous();
        return;
      }
      final existingIds = existing.regionIds.toSet();
      final nextIds = resolution.regionIds.toSet();
      if (!existingIds.containsAll(nextIds) ||
          !nextIds.containsAll(existingIds)) {
        labels[key] = const MuscleLabelResolution.ambiguous();
      }
    }

    void add(String regionId, Iterable<String> values) {
      for (final value in values) {
        register(value, MuscleLabelResolution.mapped([regionId]));
      }
    }

    void addMany(List<String> regionIds, Iterable<String> values) {
      for (final value in values) {
        register(
          value,
          MuscleLabelResolution.mapped(List.unmodifiable(regionIds)),
        );
      }
    }

    void ambiguous(Iterable<String> values) {
      for (final value in values) {
        register(value, const MuscleLabelResolution.ambiguous());
      }
    }

    add('chest', [
      'peito',
      'peitoral',
      'peitoral maior',
      'peitoral medial',
      'peitoral esternal',
      'peitoral clavicular',
      'clavicular do peitoral',
      'peitoral central',
      'peitoral menor',
    ]);
    add('upper_chest', ['peitoral superior', 'peitoral maior clavicular']);
    add('lower_chest', ['peitoral inferior']);
    add('serratus', ['serrato anterior', 'serrátil anterior']);
    add('front_deltoid', [
      'deltoide anterior',
      'deltóide anterior',
      'deltoide frontal',
    ]);
    add('side_deltoid', [
      'deltoide medial',
      'deltoide lateral',
      'deltóide medial',
      'deltóide lateral',
      'deltoide medio',
      'deltoide médio',
    ]);
    add('rear_deltoid', [
      'deltoide posterior',
      'deltóide posterior',
      'deltoide traseiro',
    ]);
    add('biceps', [
      'bíceps',
      'biceps',
      'bíceps braquial',
      'biceps braquial',
      'biceps braquial cabeça longa',
      'biceps braquial cabeça curta',
      'bíceps (cabeça curta)',
      'bíceps (cabeça longa)',
      'bíceps cabeça longa',
      'bíceps cabeça curta',
    ]);
    add('triceps', [
      'tríceps',
      'triceps',
      'tríceps braquial',
      'triceps braquial',
      'cabeça longa do tríceps',
      'cabeça medial do tríceps',
      'cabeça lateral do tríceps',
      'tríceps cabeça longa',
      'tríceps cabeça medial',
      'tríceps cabeça lateral',
      'ancôneo',
    ]);
    add('forearms', [
      'antebraço',
      'antebraços',
      'flexores do antebraço',
      'extensores do antebraço',
      'flexores do punho',
      'extensores do punho',
      'braquiorradial',
      'braquiorradiais',
      'músculos do antebraço',
      'extensor radial longo do carpo',
      'extensor radial do carpo',
      'extensor ulnar do carpo',
      'extensores dos dedos',
      'flexor radial do carpo',
      'flexor ulnar do carpo',
      'flexores dos dedos',
      'palmar longo',
      'pronador quadrado',
      'pronador redondo',
      'pronadores',
      'supinador',
    ]);
    add('brachialis', ['braquial']);
    add('abs', [
      'abdômen',
      'abdomen',
      'reto abdominal',
      'reto abdominal inferior',
      'transverso do abdômen',
      'transverso do abdomen',
    ]);
    add('obliques', [
      'oblíquos',
      'obliquos',
      'oblíquo externo',
      'oblíquo interno',
    ]);
    add('hip_flexors', [
      'flexores do quadril',
      'iliopsoas',
      'psoas',
      'reto femoral proximal',
    ]);
    add('adductors', [
      'adutores',
      'adutor longo',
      'adutor magno',
      'adutor curto',
      'pectíneo',
      'grácil',
    ]);
    add('quadriceps', [
      'quadríceps',
      'quadriceps',
      'reto femoral',
      'vasto lateral',
      'vasto medial',
      'vasto intermédio',
      'vasto intermedio',
    ]);
    add('calves', [
      'panturrilha',
      'panturrilhas',
      'gastrocnêmio',
      'gastrocnemio',
      'sóleo',
      'soleo',
    ]);
    add('traps', [
      'trapézio',
      'trapezio',
      'trapézio superior',
      'trapézio médio',
      'trapézio inferior',
      'trapezio superior',
      'trapezio medio',
      'trapezio inferior',
      'elevador da escápula',
    ]);
    add('upper_back', [
      'romboide',
      'romboides',
      'romboide maior',
      'romboide menor',
      'redondo maior',
    ]);
    add('lats', [
      'dorsais',
      'dorsal',
      'grande dorsal',
      'latíssimo do dorso',
      'latissimo do dorso',
    ]);
    add('lower_back', ['lombar', 'coluna lombar', 'quadrado lombar']);
    add('glutes', [
      'glúteos',
      'gluteos',
      'glúteo',
      'gluteo',
      'glúteo máximo',
      'gluteo maximo',
      'glúteo médio',
      'gluteo medio',
      'glúteo mínimo',
      'gluteo minimo',
      'gluteus maximus',
      'gluteus medius',
      'gluteus minimus',
      'piriforme',
      'abdutores',
      'tfl',
      'tensor da fáscia lata',
    ]);
    add('hamstrings', [
      'posterior',
      'posteriores',
      'posterior de coxa',
      'posteriores de coxa',
      'isquiotibiais',
      'bíceps femoral',
      'semitendíneo',
      'semimembranoso',
      'semimembranáceo',
    ]);
    add('neck', [
      'esternocleidomastoideo',
      'escalenos',
      'pescoço',
      'músculos do pescoço',
      'músculos cervicais',
    ]);
    add('rotator_cuff', [
      'manguito rotador',
      'rotadores externos do ombro',
      'rotadores internos do ombro',
      'subescapular',
      'redondo menor',
      'teres menor',
      'infraespinal',
      'infraespinhal',
      'supraespinal',
      'supra-espinal',
    ]);
    add('tibialis', ['tibial anterior']);
    add('spinal_erectors', [
      'eretores da espinha',
      'eretores da coluna',
      'eretores da coluna lombar',
      'eretores da coluna torácica',
      'erétores da espinha',
      'erétores da coluna',
      'erétores da coluna lombar',
      'erétores da coluna torácica',
      'eretores espinhais',
      'erectores da coluna',
      'multífideos',
    ]);
    add('upper_back', ['teres maior', 'redondo maior']);
    add('traps', ['levantador da escápula', 'trapézio médio e inferior']);
    add('hip_flexors', [
      'flexor do quadril',
      'flexores do quadril',
      'hip flexores',
      'hip flexor',
      'iliopsoas',
      'psoas',
    ]);
    add('adductors', ['adutores da coxa']);
    add('hands', [
      'intrínsecos da mão',
      'lumbricais',
      'thenar',
      'hipotenar',
      'músculos intrínsecos da mão',
    ]);
    addMany(
      ['side_deltoid', 'rear_deltoid'],
      ['deltóide lateral e posterior', 'deltoide lateral e posterior'],
    );

    ambiguous([
      'ombro',
      'ombros',
      'deltoide',
      'deltóide',
      'deltóides',
      'core',
      'costas',
      'dorso',
      'braço',
      'braços',
      'pernas',
      'coxa',
      'core profundo',
      'rotadores da coluna',
      'intercostais',
      'rotadores externos do quadril',
    ]);
    return Map.unmodifiable(labels);
  }
}

/// Applies only the catalog's stored primary/secondary distinction.
class ExerciseMuscleMapper {
  const ExerciseMuscleMapper();

  ExerciseMuscleAnatomy map(ExercicioModel exercise) =>
      MuscleAnatomyTaxonomy.mapExercise(exercise);
}
