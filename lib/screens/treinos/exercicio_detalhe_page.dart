import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';
import '../../models/coach_insight_model.dart';
import '../../models/exercicio_model.dart';
import '../../models/exercise_progression_model.dart';
import '../../models/treino_model.dart';
import '../../services/coach_insight_service.dart';
import '../../services/exercise_progression_service.dart';
import '../../services/progressao_service.dart';
import '../../services/storage_service.dart';
import '../../services/treino_service.dart';
import 'treino_em_andamento_page.dart';
import 'treino_navigation.dart';
import 'widgets/exercise_coach_insights_card.dart';
import 'widgets/exercise_next_progression_card.dart';
import 'widgets/exercise_notes_card.dart';
import 'widgets/exercise_records_card.dart';
import 'widgets/exercise_hub_widgets.dart';
import 'widgets/plans/plan_media.dart';

class ExercicioDetalhePage extends StatefulWidget {
  const ExercicioDetalhePage({
    super.key,
    required this.exercicio,
    this.onConcluir,
  });

  final ExercicioModel exercicio;
  final VoidCallback? onConcluir;

  @override
  State<ExercicioDetalhePage> createState() => _ExercicioDetalhePageState();
}

class _ExercicioDetalhePageState extends State<ExercicioDetalhePage> {
  late Future<ResumoCargaExercicio> _resumoCargaFuture;
  late Future<ExerciseProgressionModel> _nextProgressionFuture;
  late Future<List<CoachInsightModel>> _coachInsightsFuture;
  final GlobalKey _historyKey = GlobalKey();
  var _tabIndex = 0;
  var _favorito = false;

  ExercicioModel get exercicio => widget.exercicio;

  @override
  void initState() {
    super.initState();
    _loadFutures();
    _carregarFavorito();
  }

  @override
  void didUpdateWidget(covariant ExercicioDetalhePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercicio.id != exercicio.id ||
        oldWidget.exercicio.nome != exercicio.nome) {
      _loadFutures();
      _carregarFavorito();
    }
  }

  void _loadFutures() {
    _resumoCargaFuture = const ProgressaoService().carregarResumoCarga(
      exercicio: exercicio,
    );
    _nextProgressionFuture = const ExerciseProgressionService().generate(
      exercise: exercicio,
      config: ExerciseProgressionConfig(
        sets: _sets,
        repRange: _reps,
        restSeconds: _rest,
        goal: exercicio.objetivo,
        level: exercicio.dificuldade,
      ),
    );
    _coachInsightsFuture = const CoachInsightService().gerarInsightsExercicio(
      exercicio,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                FitHeader(
                  title: exercicio.nome,
                  subtitle: exercicio.categoria,
                  showBackButton: true,
                  onBack: () => TreinoNavigation.popOrHome(context),
                  actions: [
                    FitIconButton(
                      icon: _favorito
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      tooltip: _favorito
                          ? 'Remover dos favoritos'
                          : 'Adicionar aos favoritos',
                      onPressedAsync: _alternarFavorito,
                    ),
                  ],
                ),
                _tabs(),
                const FitDivider(),
                Expanded(
                  child: IndexedStack(
                    index: _tabIndex,
                    children: [_execution(), _muscles(), _tips()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          FitSpacing.s20,
          FitSpacing.s8,
          FitSpacing.s20,
          FitSpacing.s16,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: FitButton(
              label: widget.onConcluir == null
                  ? 'Iniciar treino rapido'
                  : 'Adicionar ao treino',
              icon: widget.onConcluir == null
                  ? Icons.play_arrow_rounded
                  : Icons.add_rounded,
              onPressed: _executarAgora,
              expand: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabs() {
    const labels = ['Execucao', 'Musculos', 'Dicas'];
    return Row(
      children: List.generate(labels.length, (index) {
        final selected = _tabIndex == index;
        return Expanded(
          child: InkWell(
            onTap: () => setState(() => _tabIndex = index),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    labels[index],
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? FitColors.primary
                          : FitColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  AnimatedContainer(
                    duration: FitDuration.fast,
                    height: 2,
                    color: selected ? FitColors.primary : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _execution() {
    return ListView(
      key: const PageStorageKey('exercise-execution'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        FitSpacing.s20,
        FitSpacing.s16,
        FitSpacing.s20,
        FitSpacing.s24,
      ),
      children: [
        AspectRatio(
          aspectRatio: 1.35,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: ExerciseMedia(exercise: exercicio)),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: FitColors.background.withAlpha(180),
                  shape: BoxShape.circle,
                  border: Border.all(color: FitColors.primary),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: FitColors.primaryLight,
                  size: 34,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FitSpacing.s20),
        Row(
          children: [
            const Icon(Icons.data_saver_on_rounded, color: FitColors.primary),
            const SizedBox(width: FitSpacing.s8),
            Expanded(
              child: Text(
                '$_sets series x $_reps reps',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: _showProgression,
              child: const Text('Alterar'),
            ),
          ],
        ),
        const SizedBox(height: FitSpacing.s16),
        FitCard(
          variant: FitCardVariant.outlined,
          padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s16),
          child: Column(
            children: [
              _InfoRow(label: 'Descanso', value: '$_rest seg'),
              const FitDivider(),
              FutureBuilder<ExerciseProgressionModel>(
                future: _nextProgressionFuture,
                builder: (context, snapshot) {
                  final value =
                      snapshot.hasData && snapshot.data!.suggestedWeight > 0
                      ? '${_number(snapshot.data!.suggestedWeight)} kg'
                      : 'Sem dados';
                  return _InfoRow(label: 'Carga sugerida', value: value);
                },
              ),
              const FitDivider(),
              _InfoRow(label: 'Equipamento', value: _equipment),
            ],
          ),
        ),
      ],
    );
  }

  Widget _muscles() {
    final primary = exercicio.musculos.isEmpty
        ? [exercicio.categoria]
        : exercicio.musculos;
    final secondary = exercicio.musculosSecundarios;
    return ListView(
      key: const PageStorageKey('exercise-muscles'),
      padding: const EdgeInsets.all(FitSpacing.s20),
      children: [
        FitSection(
          title: 'Musculos principais',
          child: Wrap(
            spacing: FitSpacing.s8,
            runSpacing: FitSpacing.s8,
            children: primary
                .where((name) => name.trim().isNotEmpty)
                .map((name) => FitTagChip(label: name))
                .toList(growable: false),
          ),
        ),
        if (secondary.isNotEmpty) ...[
          const SizedBox(height: FitSpacing.s24),
          FitSection(
            title: 'Musculos secundarios',
            child: Wrap(
              spacing: FitSpacing.s8,
              runSpacing: FitSpacing.s8,
              children: secondary
                  .map((name) => FitTagChip(label: name))
                  .toList(growable: false),
            ),
          ),
        ],
        const SizedBox(height: FitSpacing.s24),
        FitCard(
          variant: FitCardVariant.outlined,
          child: Text(
            exercicio.descricao.trim().isEmpty
                ? 'Descricao muscular nao informada.'
                : exercicio.descricao,
          ),
        ),
      ],
    );
  }

  Widget _tips() {
    return FutureBuilder<ResumoCargaExercicio>(
      future: _resumoCargaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const FitLoading.fullScreen(label: 'Carregando exercicio');
        }
        if (snapshot.hasError) {
          return FitErrorState(
            title: 'Dados indisponiveis',
            error: 'Nao foi possivel carregar o historico deste exercicio.',
            onRetry: _reload,
          );
        }
        final summary = snapshot.data;
        return ListView(
          key: const PageStorageKey('exercise-tips'),
          padding: const EdgeInsets.all(FitSpacing.s20),
          children: [
            ExerciseTechniqueCard(exercicio: exercicio),
            const SizedBox(height: FitSpacing.s12),
            ExerciseCoachInsightsCard(future: _coachInsightsFuture),
            const SizedBox(height: FitSpacing.s12),
            ExerciseNextProgressionCard(
              future: _nextProgressionFuture,
              onApply: _aceitarProximaProgressao,
              onKeep: _keepCurrent,
              onViewHistory: _showHistory,
            ),
            const SizedBox(height: FitSpacing.s12),
            KeyedSubtree(
              key: _historyKey,
              child: ExerciseHistoryCard(resumo: summary),
            ),
            const SizedBox(height: FitSpacing.s12),
            ExerciseStatsCard(resumo: summary),
            const SizedBox(height: FitSpacing.s12),
            ExerciseRecordsCard(exercicio: exercicio),
            const SizedBox(height: FitSpacing.s12),
            ExerciseNotesCard(exercicio: exercicio),
          ],
        );
      },
    );
  }

  Future<void> _carregarFavorito() async {
    final favorites = await StorageService.carregarFavoritosExercicios();
    if (!mounted) return;
    setState(() {
      _favorito =
          favorites.contains(_favoriteId) ||
          favorites.contains(exercicio.id) ||
          favorites.contains(exercicio.nome);
    });
  }

  Future<void> _alternarFavorito() async {
    final value = await StorageService.alternarFavoritoExercicio(_favoriteId);
    if (mounted) setState(() => _favorito = value);
  }

  Future<void> _aceitarProximaProgressao() async {
    final progression = await _nextProgressionFuture;
    await const ExerciseProgressionService().accept(progression);
    if (!mounted) return;
    FitFeedback.showSuccess(context, 'Sugestao salva para a proxima execucao.');
  }

  void _keepCurrent() {
    FitFeedback.showSuccess(context, 'Configuracao atual mantida.');
  }

  void _showHistory() {
    setState(() => _tabIndex = 2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _historyKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(target, duration: FitDuration.normal);
      }
    });
  }

  Future<void> _showProgression() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FitBottomSheet(
        title: 'Ajustar progressao',
        child: ExerciseNextProgressionCard(
          future: _nextProgressionFuture,
          onApply: _aceitarProximaProgressao,
          onKeep: _keepCurrent,
          onViewHistory: _showHistory,
        ),
      ),
    );
  }

  void _reload() {
    setState(_loadFutures);
  }

  Future<void> _executarAgora() async {
    if (widget.onConcluir != null) {
      widget.onConcluir!.call();
      _reload();
      return;
    }
    final workout = TreinoModel(
      id: 'treino_rapido_${DateTime.now().millisecondsSinceEpoch}',
      nome: 'Treino rapido - ${exercicio.nome}',
      descricao: 'Treino rapido criado a partir do Exercise Hub.',
      objetivo: exercicio.objetivo.trim().isEmpty
          ? 'Treino rapido'
          : exercicio.objetivo,
      nivel: exercicio.dificuldade.trim().isEmpty
          ? 'Livre'
          : exercicio.dificuldade,
      tempoEstimado: 12,
      exercicios: [exercicio],
      criadoPorIA: false,
      dataCriacao: DateTime.now().toIso8601String(),
    );
    TreinoService.instance.adicionarTreino(workout);
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => TreinoEmAndamentoPage(treino: workout)),
    );
    if (mounted) _reload();
  }

  int get _sets => exercicio.series <= 0 ? 3 : exercicio.series;
  String get _reps =>
      exercicio.repeticoes.trim().isEmpty ? '8-12' : exercicio.repeticoes;
  int get _rest =>
      exercicio.descansoSegundos <= 0 ? 60 : exercicio.descansoSegundos;
  String get _equipment => exercicio.equipamentos.isEmpty
      ? 'Nao informado'
      : exercicio.equipamentos.first;
  String get _favoriteId =>
      exercicio.id.trim().isEmpty ? exercicio.nome.trim() : exercicio.id;

  String _number(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1).replaceAll('.', ',');
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: FitSpacing.s16),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
