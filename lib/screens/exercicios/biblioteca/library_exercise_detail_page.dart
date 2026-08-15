import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/components/fit_button.dart';
import '../../../design_system/components/fit_editorial.dart';
import '../../../design_system/tokens/fit_colors.dart';
import '../../../design_system/tokens/fit_layout.dart';
import '../../../design_system/tokens/fit_radius.dart';
import '../../../design_system/tokens/fit_spacing.dart';
import '../../../core/exercises/exercise_library_intelligence.dart';
import '../../../models/exercicio_model.dart';
import '../../../models/exercise_history_model.dart';
import '../../../models/exercise_progression_model.dart';
import '../../../models/treino_model.dart';
import '../../../services/exercise_history_service.dart';
import '../../../services/exercise_progression_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/exercicio_gif_viewer.dart';
import '../../treinos/treino_em_andamento_page.dart';
import '../../treinos/widgets/exercise_next_progression_card.dart';
import 'library_catalog_controller.dart';
import 'library_comparison_sheet.dart';
import 'library_plan_actions.dart';
import 'library_official_widgets.dart';

typedef LibraryFavoriteToggle = Future<bool> Function(ExercicioModel exercise);

class BibliotecaExercicioDetalhePage extends StatefulWidget {
  const BibliotecaExercicioDetalhePage({
    super.key,
    required this.exercicio,
    this.permitirSelecao = false,
    this.initialFavorite = false,
    this.onToggleFavorite,
    this.onOpenFavorites,
    this.relatedExercises = const [],
    this.relatedRecommendations = const [],
    this.substitutions = const [],
    this.onOpenRelated,
    this.onToggleRelated,
    this.onSelectionConfirmed,
    this.onPlanAdded,
    this.onQuickWorkoutStarted,
  });

  final ExercicioModel exercicio;
  final bool permitirSelecao;
  final bool initialFavorite;
  final LibraryFavoriteToggle? onToggleFavorite;
  final VoidCallback? onOpenFavorites;
  final List<ExercicioModel> relatedExercises;
  final List<ExerciseRecommendation> relatedRecommendations;
  final List<ExerciseSubstitution> substitutions;
  final ValueChanged<ExercicioModel>? onOpenRelated;
  final ValueChanged<ExercicioModel>? onToggleRelated;
  final Future<void> Function()? onSelectionConfirmed;
  final Future<void> Function()? onPlanAdded;
  final Future<void> Function()? onQuickWorkoutStarted;

  @override
  State<BibliotecaExercicioDetalhePage> createState() =>
      _BibliotecaExercicioDetalhePageState();
}

class _BibliotecaExercicioDetalhePageState
    extends State<BibliotecaExercicioDetalhePage> {
  var _favorite = false;
  var _showTabs = false;
  var _tabIndex = 0;
  var _favoriteBusy = false;

  late final Future<ExerciseHistorySnapshot> _historyFuture;
  late final Future<ExerciseProgressionModel> _progressionFuture;

  ExercicioModel get exercise => widget.exercicio;

  @override
  void initState() {
    super.initState();
    _favorite = widget.initialFavorite || exercise.favorito;
    _historyFuture = const ExerciseHistoryService().loadExerciseHistory(
      exercise,
    );
    _progressionFuture = const ExerciseProgressionService().generate(
      exercise: exercise,
      config: ExerciseProgressionConfig(
        sets: exercise.series > 0 ? exercise.series : 4,
        repRange: exercise.repeticoes.trim().isNotEmpty
            ? exercise.repeticoes
            : '8-12',
        restSeconds: exercise.descansoSegundos > 0
            ? exercise.descansoSegundos
            : 90,
        goal: exercise.objetivo,
        level: exercise.dificuldade,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: !_showTabs,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _showTabs) setState(() => _showTabs = false);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _showTabs ? _tabsView() : _summaryView(),
          ),
        ),
        bottomNavigationBar: _bottomAction(),
      ),
    );
  }

  Widget _summaryView() {
    return CustomScrollView(
      key: const ValueKey('LIB-004'),
      primary: false,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _hero()),
        SliverToBoxAdapter(
          child: LibraryContentFrame(
            padding: const EdgeInsets.fromLTRB(
              FitSpacing.s16,
              FitSpacing.s20,
              FitSpacing.s16,
              FitSpacing.s32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _exerciseHeading(),
                const SizedBox(height: FitSpacing.s20),
                _metrics(),
                const SizedBox(height: FitSpacing.s24),
                _musclesSummary(),
                const SizedBox(height: FitSpacing.s24),
                _description(),
                const SizedBox(height: FitSpacing.s24),
                _exerciseDetails(),
                if (widget.relatedRecommendations.isNotEmpty) ...[
                  const SizedBox(height: FitSpacing.s24),
                  _relatedExercises(),
                ],
                if (widget.substitutions.isNotEmpty) ...[
                  const SizedBox(height: FitSpacing.s24),
                  _substitutions(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _hero() {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: AspectRatio(
            aspectRatio: FitLayout.domainMediaAspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                LibraryExerciseMedia(exercise: exercise, fit: BoxFit.contain),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [Color(0x80000000), Colors.transparent],
                    ),
                  ),
                ),
                Positioned(
                  left: FitSpacing.s12,
                  top: FitSpacing.s8,
                  child: LibraryIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Voltar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  right: FitSpacing.s64,
                  top: FitSpacing.s8,
                  child: LibraryIconButton(
                    icon: Icons.share_outlined,
                    tooltip: 'Compartilhar exercicio',
                    onPressed: _shareExercise,
                  ),
                ),
                Positioned(
                  right: FitSpacing.s12,
                  top: FitSpacing.s8,
                  child: LibraryIconButton(
                    icon: _favorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    tooltip: _favorite ? 'Remover dos favoritos' : 'Favoritar',
                    selected: _favorite,
                    onPressed: _favoriteBusy ? null : _toggleFavorite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _exerciseHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exercise.nome,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: FitSpacing.s8),
        Row(
          children: [
            Expanded(
              child: Text(
                exercise.categoria,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              _difficulty,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: libraryDifficultyColor(context, _difficulty),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metrics() {
    return FitMetricRail(
      items: [
        FitMetricRailItem(
          label: 'Séries',
          value: '${exercise.series > 0 ? exercise.series : 4}',
          icon: Icons.format_list_numbered_rounded,
        ),
        FitMetricRailItem(
          label: 'Repetições',
          value: _repetitions,
          icon: Icons.repeat_rounded,
        ),
        FitMetricRailItem(
          label: 'Descanso',
          value: '${_restSeconds}s',
          icon: Icons.timer_outlined,
        ),
        FitMetricRailItem(
          label: 'Equipamento',
          value: _primaryEquipment,
          icon: Icons.fitness_center_rounded,
        ),
      ],
    );
  }

  Widget _musclesSummary() {
    final primary = exercise.musculos.isEmpty
        ? exercise.categoria
        : exercise.musculos.first;
    final secondary = exercise.musculosSecundarios.take(2).toList();
    final group = _groupForExercise();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Músculos trabalhados',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: FitSpacing.s12),
        Row(
          children: [
            SizedBox(
              width: 92,
              height: 106,
              child: LibraryMuscleGlyph(group: group, large: true),
            ),
            const SizedBox(width: FitSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legend(primary, FitColors.primary),
                  for (var index = 0; index < secondary.length; index++)
                    _legend(
                      secondary[index],
                      index == 0 ? FitColors.danger : FitColors.info,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legend(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FitSpacing.s4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: FitSpacing.s8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _description() {
    final description = exercise.descricao.trim().isEmpty
        ? 'Descrição técnica ainda não cadastrada para este exercício.'
        : exercise.descricao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Descrição', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: FitSpacing.s8),
        Text(
          description,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() => _showTabs = true),
            child: const Text('Ver mais'),
          ),
        ),
      ],
    );
  }

  Widget _exerciseDetails() {
    final breathing = 'Expire na fase de esforco e inspire no retorno.';
    final tips = exercise.observacoesTreino.trim().isEmpty
        ? 'Priorize amplitude controlada e carga compativel com a tecnica.'
        : exercise.observacoesTreino;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow(
          'Execução',
          exercise.comoExecutar,
          Icons.format_list_numbered_rounded,
        ),
        const Divider(),
        _detailRow('Respiração', breathing, Icons.air_rounded),
        const Divider(),
        _detailRow('Dicas', tips, Icons.lightbulb_outline_rounded),
        if (exercise.tags.isNotEmpty) ...[
          const SizedBox(height: FitSpacing.s16),
          Text('Tags', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: FitSpacing.s8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in exercise.tags)
                Chip(label: Text(tag), visualDensity: VisualDensity.compact),
            ],
          ),
        ],
      ],
    );
  }

  Widget _detailRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FitSpacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: FitLayout.iconSizeButton,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: FitSpacing.s4),
                Text(
                  value.trim().isEmpty ? 'Não informado.' : value,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _relatedExercises() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Variacoes e relacionados',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const ValueKey('library_compare_button'),
            onPressed: () => showLibraryExerciseComparisonSheet(
              context: context,
              source: exercise,
              candidates: widget.relatedRecommendations,
            ),
            icon: const Icon(Icons.compare_arrows_rounded, size: 18),
            label: const Text('Comparar'),
          ),
        ),
        const SizedBox(height: FitSpacing.s4),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.relatedRecommendations.length,
            separatorBuilder: (_, _) => const SizedBox(width: FitSpacing.s8),
            itemBuilder: (context, index) {
              final recommendation = widget.relatedRecommendations[index];
              final related = recommendation.exercise;
              return Semantics(
                label:
                    '${related.nome}. ${recommendation.reasons.first.label}.',
                child: SizedBox(
                  width: 176,
                  child: LibraryExerciseTile(
                    exercise: related,
                    favorite: related.favorito,
                    compact: true,
                    onTap: () => widget.onOpenRelated?.call(related),
                    onFavorite: () => widget.onToggleRelated?.call(related),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _substitutions() {
    final suggestions = widget.substitutions.take(3).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alternativas compativeis',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: FitSpacing.s8),
        for (final substitution in suggestions)
          Semantics(
            button: true,
            label:
                '${substitution.exercise.nome}. ${_substitutionLabel(substitution.kind)}.',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                substitution.exercise.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              subtitle: Text(
                _substitutionDescription(substitution),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 16,
              ),
              onTap: () => widget.onOpenRelated?.call(substitution.exercise),
            ),
          ),
      ],
    );
  }

  Widget _tabsView() {
    return Column(
      key: const ValueKey('LIB-005-007'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FitSpacing.s12,
            FitSpacing.s8,
            FitSpacing.s16,
            FitSpacing.s4,
          ),
          child: Row(
            children: [
              LibraryIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Voltar aos detalhes',
                onPressed: () => setState(() => _showTabs = false),
              ),
              const SizedBox(width: FitSpacing.s12),
              Expanded(
                child: Text(
                  exercise.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
        LibrarySegmentTabs<int>(
          values: const [0, 1, 2],
          selected: _tabIndex,
          labelFor: (value) => switch (value) {
            0 => 'Instruções',
            1 => 'Músculos',
            _ => 'Erros comuns',
          },
          onSelected: (value) => setState(() => _tabIndex = value),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: switch (_tabIndex) {
              0 => _instructionsTab(),
              1 => _musclesTab(),
              _ => _errorsTab(),
            },
          ),
        ),
      ],
    );
  }

  Widget _instructionsTab() {
    final steps = _instructionSteps();
    return ListView(
      key: const ValueKey('LIB-005'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        FitSpacing.s16,
        FitSpacing.s12,
        FitSpacing.s16,
        FitSpacing.s32,
      ),
      children: [
        for (final step in steps) _instructionRow(step),
        const SizedBox(height: FitSpacing.s12),
        ClipRRect(
          borderRadius: FitRadius.smallBorder,
          child: AspectRatio(
            aspectRatio: 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                LibraryExerciseMedia(exercise: exercise, fit: BoxFit.cover),
                Center(
                  child: Material(
                    color: Colors.black.withAlpha(165),
                    shape: const CircleBorder(
                      side: BorderSide(color: FitColors.textSecondary),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _showGif,
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: FitColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: const Color(0xDD151B1E),
                    child: InkWell(
                      onTap: _showGif,
                      child: const SizedBox(
                        height: 36,
                        child: Center(
                          child: Text(
                            'Ver animação 3D',
                            style: TextStyle(
                              color: FitColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: FitSpacing.s24),
        _legacyInsights(),
      ],
    );
  }

  Widget _instructionRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FitSpacing.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.check_circle_rounded,
              color: FitColors.primary,
              size: 17,
            ),
          ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _musclesTab() {
    final group = _groupForExercise();
    final primary = exercise.musculos.isEmpty
        ? <String>[exercise.categoria]
        : exercise.musculos;
    final secondary = exercise.musculosSecundarios;
    return ListView(
      key: const ValueKey('LIB-006'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        FitSpacing.s16,
        FitSpacing.s16,
        FitSpacing.s16,
        FitSpacing.s32,
      ),
      children: [
        SizedBox(
          height: 230,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: LibraryMuscleGlyph(group: group, large: true),
                    ),
                    Text(
                      'Frente',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: LibraryMuscleGlyph(group: group, large: true),
                    ),
                    Text(
                      'Costas',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FitSpacing.s12),
        for (final muscle in primary) _legend(muscle, FitColors.primary),
        for (var index = 0; index < secondary.length; index++)
          _legend(
            secondary[index],
            index == 0 ? FitColors.danger : FitColors.info,
          ),
        const SizedBox(height: FitSpacing.s16),
        const Divider(),
        const SizedBox(height: FitSpacing.s12),
        Text(
          'Músculos secundários',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: FitSpacing.s8),
        Text(
          secondary.isEmpty ? 'Não informado' : secondary.join(', '),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _errorsTab() {
    final errors = _commonErrors();
    return ListView.separated(
      key: const ValueKey('LIB-007'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        FitSpacing.s16,
        FitSpacing.s16,
        FitSpacing.s16,
        FitSpacing.s32,
      ),
      itemCount: errors.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = errors[index];
        final words = item.split(RegExp(r'\s+'));
        final title = words.take(5).join(' ');
        return Container(
          height: 82,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: FitRadius.smallBorder,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              SizedBox(
                width: 92,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LibraryExerciseMedia(exercise: exercise),
                    const Positioned(
                      right: 4,
                      top: 4,
                      child: Icon(
                        Icons.cancel_rounded,
                        color: FitColors.danger,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _legacyInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histórico e progressão',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: FitSpacing.s12),
        FutureBuilder<ExerciseHistorySnapshot>(
          future: _historyFuture,
          builder: (context, snapshot) {
            final history = snapshot.data;
            final count = history?.executions.length ?? 0;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(FitSpacing.s12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: FitRadius.smallBorder,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Text(
                count == 0
                    ? 'Nenhuma execução registrada.'
                    : '$count execuções registradas neste exercício.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          },
        ),
        const SizedBox(height: FitSpacing.s12),
        ExerciseNextProgressionCard(
          future: _progressionFuture,
          onApply: _acceptProgression,
          onKeep: _keepProgression,
          onViewHistory: () {},
        ),
      ],
    );
  }

  Widget _bottomAction() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          FitSpacing.s16,
          FitSpacing.s8,
          FitSpacing.s16,
          FitSpacing.s12,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 648),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FitButton(
                  label: widget.permitirSelecao
                      ? 'Selecionar exercicio'
                      : 'Adicionar ao plano',
                  icon: widget.permitirSelecao
                      ? Icons.check_circle_outline_rounded
                      : Icons.playlist_add_rounded,
                  onPressedAsync: widget.permitirSelecao
                      ? _confirmSelection
                      : _addToPlan,
                  expand: true,
                ),
                if (!widget.permitirSelecao) ...[
                  const SizedBox(height: FitSpacing.s8),
                  FitButton(
                    label: 'Iniciar treino rapido',
                    icon: Icons.play_arrow_rounded,
                    variant: FitButtonVariant.secondary,
                    onPressedAsync: _executeNow,
                    expand: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSelection() async {
    try {
      await widget.onSelectionConfirmed?.call();
      if (mounted) Navigator.of(context).pop(exercise);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel salvar a selecao neste dispositivo.'),
        ),
      );
    }
  }

  Future<void> _addToPlan() async {
    final result = await showLibraryAddToPlanSheet(
      context: context,
      exercise: exercise,
    );
    if (!mounted || result == null) return;
    await widget.onPlanAdded?.call();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${exercise.nome} adicionado a ${result.plan.nome}.'),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    setState(() => _favoriteBusy = true);
    try {
      final callback = widget.onToggleFavorite;
      final favorite = callback == null
          ? await StorageService.alternarFavoritoExercicio(exercise.id)
          : await callback(exercise);
      if (!mounted) return;
      setState(() {
        _favorite = favorite;
        exercise.favorito = favorite;
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            favorite
                ? 'Exercício adicionado aos favoritos.'
                : 'Exercício removido dos favoritos.',
          ),
          action: favorite && widget.onOpenFavorites != null
              ? SnackBarAction(
                  label: 'Ver favoritos',
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onOpenFavorites?.call();
                  },
                )
              : null,
        ),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel salvar este favorito localmente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  Future<void> _executeNow() async {
    final now = DateTime.now();
    await widget.onQuickWorkoutStarted?.call();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TreinoEmAndamentoPage(
          treino: TreinoModel(
            id: 'execucao_${exercise.id}_${now.microsecondsSinceEpoch}',
            nome: 'Treino rápido - ${exercise.nome}',
            descricao: 'Execução rápida iniciada pela Biblioteca.',
            objetivo: exercise.objetivo,
            nivel: exercise.dificuldade,
            tempoEstimado: 8,
            criadoPorIA: false,
            exercicios: [exercise],
            dataCriacao: now.toIso8601String(),
          ),
        ),
      ),
    );
  }

  Future<void> _acceptProgression() async {
    final progression = await _progressionFuture;
    await const ExerciseProgressionService().accept(progression);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sugestão salva para a próxima execução.')),
    );
  }

  void _keepProgression() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuração atual mantida.')),
    );
  }

  void _showGif() {
    mostrarGifExercicioTelaCheia(
      context,
      imagem: exercise.imagem,
      gifPath: exercise.gifPath,
      titulo: exercise.nome,
      subtitulo: exercise.categoria,
    );
  }

  static String _substitutionLabel(ExerciseSubstitutionKind kind) =>
      switch (kind) {
        ExerciseSubstitutionKind.equivalent => 'Equivalente',
        ExerciseSubstitutionKind.sameMuscle => 'Mesmo musculo',
        ExerciseSubstitutionKind.sameMovement => 'Mesmo movimento',
        ExerciseSubstitutionKind.sameEquipment => 'Mesmo equipamento',
        ExerciseSubstitutionKind.noEquipment => 'Sem equipamento',
        ExerciseSubstitutionKind.easier => 'Menor dificuldade',
        ExerciseSubstitutionKind.harder => 'Maior dificuldade',
      };

  static String _substitutionDescription(ExerciseSubstitution substitution) {
    final preserved = substitution.preserved.isEmpty
        ? 'Alternativa baseada no catalogo local.'
        : 'Preserva ${substitution.preserved.join(', ')}.';
    if (substitution.changed.isEmpty) return preserved;
    return '$preserved Muda ${substitution.changed.join(', ')}.';
  }

  Future<void> _shareExercise() async {
    await Clipboard.setData(
      ClipboardData(text: '${exercise.nome} - ${exercise.categoria}'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informacoes do exercicio copiadas.')),
    );
  }

  List<String> _instructionSteps() {
    final parsed = _splitText(exercise.comoExecutar);
    const fallback = [
      'Ajuste a posição e mantenha os apoios firmes.',
      'Inicie o movimento com controle e alinhamento.',
      'Complete a amplitude sem perder a postura.',
      'Retorne lentamente à posição inicial.',
      'Mantenha a respiração e a tensão muscular.',
    ];
    return List.generate(5, (index) {
      return index < parsed.length ? parsed[index] : fallback[index];
    });
  }

  List<String> _commonErrors() {
    final parsed = _splitText(exercise.cuidados);
    const fallback = [
      'Arquear demais as costas durante o movimento.',
      'Perder o apoio dos pés e a estabilidade.',
      'Executar a fase de retorno rápido demais.',
      'Abrir os cotovelos além do necessário.',
    ];
    return List.generate(4, (index) {
      return index < parsed.length ? parsed[index] : fallback[index];
    });
  }

  List<String> _splitText(String value) {
    return value
        .split(RegExp(r'[\n.;]+'))
        .map((item) => item.trim())
        .where((item) => item.length > 8)
        .toList(growable: false);
  }

  LibraryMuscleGroup _groupForExercise() {
    final text = normalizeLibraryText(
      [exercise.categoria, ...exercise.musculos].join(' '),
    );
    return LibraryCatalogController.muscleGroups.firstWhere(
      (group) => group.aliases.any(
        (alias) => text.contains(normalizeLibraryText(alias)),
      ),
      orElse: () => LibraryCatalogController.muscleGroups.first,
    );
  }

  String get _difficulty => exercise.dificuldade.trim().isEmpty
      ? 'Intermediário'
      : exercise.dificuldade;
  String get _repetitions =>
      exercise.repeticoes.trim().isEmpty ? '8-12' : exercise.repeticoes;
  int get _restSeconds =>
      exercise.descansoSegundos > 0 ? exercise.descansoSegundos : 90;
  String get _primaryEquipment =>
      exercise.equipamentos.isEmpty ? 'Livre' : exercise.equipamentos.first;
}
