import 'package:fitai/core/exercises/muscle_anatomy_taxonomy.dart';
import 'package:fitai/data/exercicios/exercicios.dart';

void main(List<String> args) {
  final allLabels = <String>{};
  final statusCounts = <MuscleMappingStatus, int>{};
  final issues = <ExerciseMuscleAnatomy>[];
  final ids = bancoExercicios.map((exercise) => exercise.id.trim()).toList();
  final idSet = ids.toSet();
  final invalidIds = <String>{};
  final invalidMuscleIds = <String>{};
  var sourceRoleConflicts = 0;
  var duplicatePrimary = 0;
  var duplicateSecondary = 0;
  var emptyPrimary = 0;

  for (final exercise in bancoExercicios) {
    allLabels.addAll(exercise.musculos);
    allLabels.addAll(exercise.musculosSecundarios);
    final mapping = const ExerciseMuscleMapper().map(exercise);
    statusCounts.update(
      mapping.status,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    if (mapping.status != MuscleMappingStatus.mapped) issues.add(mapping);
    if (exercise.id.trim().isEmpty) {
      invalidIds.add(exercise.id);
    }
    if (mapping.overlappingMuscleIds.isNotEmpty) sourceRoleConflicts++;
    if (mapping.primaryMuscles.toSet().length !=
        mapping.primaryMuscles.length) {
      duplicatePrimary++;
    }
    if (mapping.secondaryMuscles.toSet().length !=
        mapping.secondaryMuscles.length) {
      duplicateSecondary++;
    }
    if (exercise.musculos.isNotEmpty && mapping.primaryMuscles.isEmpty) {
      emptyPrimary++;
    }
    for (final id in [...mapping.primaryMuscles, ...mapping.secondaryMuscles]) {
      if (!MuscleAnatomyTaxonomy.byId.containsKey(id)) invalidMuscleIds.add(id);
    }
  }

  invalidIds.addAll(
    idSet.where((id) => ids.where((candidate) => candidate == id).length > 1),
  );
  // No per-exercise override table exists in this version, so there are no
  // independent mapping records that could become orphaned.
  const orphanIds = <String>{};
  final total = bancoExercicios.length;
  final mapped = statusCounts[MuscleMappingStatus.mapped] ?? 0;
  // ignore: avoid_print
  print('MUSCLE_MAPPING_AUDIT taxonomy=${MuscleAnatomyTaxonomy.version}');
  // ignore: avoid_print
  print(
    'TOTAL_EXERCISES=$total MAPPED=$mapped '
    'PARTIAL=${statusCounts[MuscleMappingStatus.partial] ?? 0} '
    'UNMAPPED=${statusCounts[MuscleMappingStatus.unmapped] ?? 0} '
    'AMBIGUOUS=${statusCounts[MuscleMappingStatus.ambiguous] ?? 0} '
    'INVALID_EXERCISE_IDS=${invalidIds.length} '
    'INVALID_MUSCLE_IDS=${invalidMuscleIds.length} '
    'ORPHANS=${orphanIds.length} '
    'COVERAGE=${total == 0 ? 0 : (mapped * 100 / total).toStringAsFixed(1)}%',
  );
  // ignore: avoid_print
  print(
    'REGIONS=${MuscleAnatomyTaxonomy.regions.length} '
    'FRONT=${MuscleAnatomyTaxonomy.regions.where((region) => region.views.contains(MuscleAnatomyView.front) && !region.views.contains(MuscleAnatomyView.back)).length} '
    'BACK=${MuscleAnatomyTaxonomy.regions.where((region) => region.views.contains(MuscleAnatomyView.back) && !region.views.contains(MuscleAnatomyView.front)).length} '
    'BOTH=${MuscleAnatomyTaxonomy.regions.where((region) => region.views.contains(MuscleAnatomyView.front) && region.views.contains(MuscleAnatomyView.back)).length}',
  );
  // ignore: avoid_print
  print('SOURCE_LABELS=${allLabels.length}');
  // ignore: avoid_print
  print(
    'SOURCE_ROLE_CONFLICT_EXERCISES=$sourceRoleConflicts '
    'DUPLICATE_PRIMARY=$duplicatePrimary '
    'DUPLICATE_SECONDARY=$duplicateSecondary '
    'EMPTY_PRIMARY=$emptyPrimary',
  );
  for (final label in allLabels.toList()..sort()) {
    final resolution = MuscleAnatomyTaxonomy.resolveLabel(label);
    if (resolution == null || resolution.ambiguous) {
      // ignore: avoid_print
      print(
        'UNRESOLVED_LABEL=$label ambiguous=${resolution?.ambiguous ?? false}',
      );
    }
  }
  if (args.contains('--verbose')) {
    for (final issue in issues) {
      // ignore: avoid_print
      print(
        'EXERCISE=${issue.exerciseId} STATUS=${issue.status.name} '
        'PRIMARY=${issue.primaryMuscles.join(",")} '
        'SECONDARY=${issue.secondaryMuscles.join(",")} '
        'UNMAPPED=${issue.unmappedLabels.join("|")} '
        'AMBIGUOUS=${issue.ambiguousLabels.join("|")} '
        'OVERLAP=${issue.overlappingMuscleIds.join("|")}',
      );
    }
  }
}
