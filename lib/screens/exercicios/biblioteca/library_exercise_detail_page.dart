import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/components/fit_button.dart';
import '../../../design_system/tokens/fit_colors.dart';
import '../../../design_system/tokens/fit_radius.dart';
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
    this.onOpenRelated,
    this.onToggleRelated,
  });

  final ExercicioModel exercicio;
  final bool permitirSelecao;
  final bool initialFavorite;
  final LibraryFavoriteToggle? onToggleFavorite;
  final VoidCallback? onOpenFavorites;
  final List<ExercicioModel> relatedExercises;
  final ValueChanged<ExercicioModel>? onOpenRelated;
  final ValueChanged<ExercicioModel>? onToggleRelated;

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
        backgroundColor: FitColors.background,
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
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _hero()),
        SliverToBoxAdapter(
          child: LibraryContentFrame(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _exerciseHeading(),
                const SizedBox(height: 12),
                _metrics(),
                const SizedBox(height: 14),
                _musclesSummary(),
                const SizedBox(height: 14),
                _description(),
                const SizedBox(height: 14),
                _exerciseDetails(),
                if (widget.relatedExercises.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _relatedExercises(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _hero() {
    return AspectRatio(
      aspectRatio: 2.15,
      child: Stack(
        fit: StackFit.expand,
        children: [
          LibraryExerciseMedia(exercise: exercise, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x99000000), Colors.transparent],
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 8,
            child: LibraryIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Voltar',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            right: 62,
            top: 8,
            child: LibraryIconButton(
              icon: Icons.share_outlined,
              tooltip: 'Compartilhar exercicio',
              onPressed: _shareExercise,
            ),
          ),
          Positioned(
            right: 10,
            top: 8,
            child: LibraryIconButton(
              icon: _favorite ? Icons.star_rounded : Icons.star_border_rounded,
              tooltip: _favorite ? 'Remover dos favoritos' : 'Favoritar',
              selected: _favorite,
              onPressed: _favoriteBusy ? null : _toggleFavorite,
            ),
          ),
        ],
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: FitColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Text(
                exercise.categoria,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FitColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              _difficulty,
              style: TextStyle(
                color: libraryDifficultyColor(_difficulty),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metrics() {
    return Row(
      children: [
        _metric('${exercise.series > 0 ? exercise.series : 4}', 'Séries'),
        _metric(_repetitions, 'Repetições'),
        _metric('${_restSeconds}s', 'Descanso'),
        _metric(_primaryEquipment, 'Equipamento'),
      ],
    );
  }

  Widget _metric(String value, String label) {
    return Expanded(
      child: Container(
        height: 58,
        decoration: const BoxDecoration(
          color: librarySurface,
          border: Border.fromBorderSide(BorderSide(color: libraryBorder)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    color: FitColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: FitColors.textHint,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
        const Text(
          'Músculos trabalhados',
          style: TextStyle(
            color: FitColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 92,
              height: 106,
              child: LibraryMuscleGlyph(group: group, large: true),
            ),
            const SizedBox(width: 14),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FitColors.textSecondary,
                fontSize: 11,
              ),
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
        const Text(
          'Descrição',
          style: TextStyle(
            color: FitColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          description,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: FitColors.textSecondary,
            fontSize: 11,
            height: 1.4,
          ),
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
        _detailRow('Execucao', exercise.comoExecutar),
        const SizedBox(height: 12),
        _detailRow('Respiracao', breathing),
        const SizedBox(height: 12),
        _detailRow('Dicas', tips),
        if (exercise.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Tags',
            style: TextStyle(
              color: FitColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
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

  Widget _detailRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: FitColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value.trim().isEmpty ? 'Nao informado.' : value,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: FitColors.textSecondary,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _relatedExercises() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Variacoes e relacionados',
          style: TextStyle(
            color: FitColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.relatedExercises.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final related = widget.relatedExercises[index];
              return SizedBox(
                width: 176,
                child: LibraryExerciseTile(
                  exercise: related,
                  favorite: related.favorito,
                  compact: true,
                  onTap: () => widget.onOpenRelated?.call(related),
                  onFavorite: () => widget.onToggleRelated?.call(related),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tabsView() {
    return Column(
      key: const ValueKey('LIB-005-007'),
      children: [
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        for (final step in steps) _instructionRow(step),
        const SizedBox(height: 12),
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
        const SizedBox(height: 24),
        _legacyInsights(),
      ],
    );
  }

  Widget _instructionRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: FitColors.textPrimary,
                fontSize: 11,
                height: 1.45,
              ),
            ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
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
                    const Text(
                      'Frente',
                      style: TextStyle(color: FitColors.textHint, fontSize: 10),
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
                    const Text(
                      'Costas',
                      style: TextStyle(color: FitColors.textHint, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final muscle in primary) _legend(muscle, FitColors.primary),
        for (var index = 0; index < secondary.length; index++)
          _legend(
            secondary[index],
            index == 0 ? FitColors.danger : FitColors.info,
          ),
        const SizedBox(height: 14),
        const Divider(color: libraryBorder),
        const SizedBox(height: 10),
        const Text(
          'Músculos secundários',
          style: TextStyle(
            color: FitColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          secondary.isEmpty ? 'Não informado' : secondary.join(', '),
          style: const TextStyle(
            color: FitColors.textSecondary,
            fontSize: 11,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _errorsTab() {
    final errors = _commonErrors();
    return ListView.separated(
      key: const ValueKey('LIB-007'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      itemCount: errors.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = errors[index];
        final words = item.split(RegExp(r'\s+'));
        final title = words.take(5).join(' ');
        return Container(
          height: 82,
          decoration: BoxDecoration(
            color: librarySurface,
            borderRadius: FitRadius.smallBorder,
            border: Border.all(color: libraryBorder),
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
                        style: const TextStyle(
                          color: FitColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FitColors.textSecondary,
                          fontSize: 10,
                          height: 1.35,
                        ),
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
        const Text(
          'Histórico e progressão',
          style: TextStyle(
            color: FitColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<ExerciseHistorySnapshot>(
          future: _historyFuture,
          builder: (context, snapshot) {
            final history = snapshot.data;
            final count = history?.executions.length ?? 0;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: librarySurface,
                borderRadius: FitRadius.smallBorder,
                border: Border.all(color: libraryBorder),
              ),
              child: Text(
                count == 0
                    ? 'Nenhuma execução registrada.'
                    : '$count execuções registradas neste exercício.',
                style: const TextStyle(
                  color: FitColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
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
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 648),
        child: FitButton(
          label: 'Adicionar ao treino',
          icon: Icons.add_circle_outline_rounded,
          onPressed: widget.permitirSelecao
              ? () => Navigator.of(context).pop(exercise)
              : _executeNow,
          expand: true,
        ),
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
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  Future<void> _executeNow() async {
    final now = DateTime.now();
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
