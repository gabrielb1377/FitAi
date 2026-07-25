import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/exercicio_model.dart';
import '../../../../models/treino_model.dart';
import '../../../../screens/treinos/controllers/plan_day_data.dart';
import '../../../../screens/treinos/controllers/plan_progress_snapshot.dart';
import '../../../../services/treino_service.dart';
import '../../workout_execution/pages/workout_preview_page.dart';
import '../widgets/planos_official_primitives.dart';

/// PLAN-013. Detalhes do plano salvo localmente.
class PlanosPlanDetailPage extends StatefulWidget {
  const PlanosPlanDetailPage({
    super.key,
    required this.plan,
    required this.progress,
    this.onXpUpdated,
  });

  final TreinoModel plan;
  final PlanProgressSnapshot progress;
  final Future<void> Function()? onXpUpdated;

  @override
  State<PlanosPlanDetailPage> createState() => _PlanosPlanDetailPageState();
}

class _PlanosPlanDetailPageState extends State<PlanosPlanDetailPage> {
  late TreinoModel _plan = widget.plan;

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress.weeklyProgress;
    final days = _days(_plan);
    return PlanosOfficialPage(
      title: '',
      onBack: () => Navigator.of(context).maybePop(),
      actions: [
        PopupMenuButton<_PlanAction>(
          tooltip: 'Opcoes do plano',
          icon: const Icon(FitIcons.more),
          onSelected: _handleAction,
          itemBuilder: (context) => const [
            PopupMenuItem(value: _PlanAction.edit, child: Text('Editar plano')),
            PopupMenuItem(
              value: _PlanAction.statistics,
              child: Text('Estatisticas'),
            ),
            PopupMenuItem(
              value: _PlanAction.calendar,
              child: Text('Calendario'),
            ),
            PopupMenuItem(
              value: _PlanAction.duplicate,
              child: Text('Duplicar plano'),
            ),
            PopupMenuItem(
              value: _PlanAction.share,
              child: Text('Compartilhar'),
            ),
            PopupMenuItem(value: _PlanAction.archive, child: Text('Arquivar')),
            PopupMenuItem(
              value: _PlanAction.delete,
              child: Text('Excluir plano'),
            ),
          ],
        ),
      ],
      bottomAction: FitPrimaryButton(
        label: 'Iniciar treino',
        icon: FitIcons.play,
        fullWidth: true,
        onPressed: () => _openWeek(days),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          FitSpacing.s16,
          FitSpacing.s4,
          FitSpacing.s16,
          FitSpacing.s24,
        ),
        children: [
          Stack(
            children: [
              PlanosPlanMedia(
                assetPath: _imageFor(_plan),
                height: FitLayout.domainChartHeight + FitSpacing.s64,
              ),
              Positioned(
                right: FitSpacing.s12,
                bottom: FitSpacing.s12,
                child: FitChip(label: _plan.objetivo, selected: true),
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s16),
          Text(_plan.nome, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: FitSpacing.s8),
          Text(
            _plan.descricao.isEmpty
                ? 'Plano focado em evolucao consistente e desempenho muscular.'
                : _plan.descricao,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: FitSpacing.s16),
          PlanosMetricRow(
            metrics: [
              PlanosMetricData(
                label: 'dias/semana',
                value: '${days.length}',
                icon: FitIcons.calendar,
              ),
              const PlanosMetricData(
                label: 'semanas',
                value: '8',
                icon: FitIcons.calendarRange,
              ),
              PlanosMetricData(
                label: 'exercicios',
                value: '${_plan.exercicios.length}',
                icon: FitIcons.exercise,
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s16),
          FitCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progresso do plano',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: FitSpacing.s12),
                FitProgress(
                  value: progress,
                  label: 'Semana 6 de 8',
                  trailing: '${(progress * 100).round()}%',
                  animate: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: FitSpacing.s24),
          FitSectionHeader(
            title: 'Treinos da semana',
            viewAllLabel: 'Ver semana',
            onViewAll: () => _openWeek(days),
          ),
          const SizedBox(height: FitSpacing.s8),
          for (final day in days) ...[
            _weekDayRow(day),
            const SizedBox(height: FitSpacing.s8),
          ],
        ],
      ),
    );
  }

  Widget _weekDayRow(PlanosPlanDayView day) {
    return FitCard(
      variant: FitCardVariant.clickable,
      onTap: () => _openDay(day),
      padding: const EdgeInsets.all(FitSpacing.s12),
      child: Row(
        children: [
          Text(day.weekday, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day.name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  day.subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            day.isToday ? FitIcons.play : FitIcons.check,
            color: day.isToday
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  void _openWeek(List<PlanosPlanDayView> days) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PlanosWeekPage(plan: _plan, days: days),
      ),
    );
  }

  void _openDay(PlanosPlanDayView day) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PlanosWorkoutDetailPage(plan: _plan, day: day),
      ),
    );
  }

  Future<void> _handleAction(_PlanAction action) async {
    switch (action) {
      case _PlanAction.edit:
        final updated = await Navigator.of(context).push<TreinoModel>(
          MaterialPageRoute(builder: (_) => PlanosEditPlanPage(plan: _plan)),
        );
        if (updated != null && mounted) setState(() => _plan = updated);
      case _PlanAction.statistics:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) =>
                PlanosStatisticsPage(plan: _plan, progress: widget.progress),
          ),
        );
      case _PlanAction.calendar:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => PlanosCalendarPage(plan: _plan)),
        );
      case _PlanAction.duplicate:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => PlanosDuplicatePage(plan: _plan)),
        );
      case _PlanAction.share:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => PlanosImportSharePage(plan: _plan)),
        );
      case _PlanAction.archive:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => PlanosArchivePage(plan: _plan)),
        );
      case _PlanAction.delete:
        await _delete();
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir plano?'),
        content: const Text(
          'Esta acao remove o plano salvo neste dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    TreinoService.instance.removerTreino(_plan.id);
    Navigator.of(context).pop();
  }
}

/// PLAN-014. Visao semanal de um plano.
class PlanosWeekPage extends StatelessWidget {
  const PlanosWeekPage({super.key, required this.plan, required this.days});

  final TreinoModel plan;
  final List<PlanosPlanDayView> days;

  @override
  Widget build(BuildContext context) {
    return PlanosOfficialPage(
      title: plan.nome,
      subtitle: 'Esta semana',
      onBack: () => Navigator.of(context).maybePop(),
      bottomAction: FitOutlinedButton(
        label: 'Editar semana',
        icon: FitIcons.edit,
        fullWidth: true,
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => PlanosCalendarPage(plan: plan)),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(FitSpacing.s16),
        children: [
          _weekdaySelector(context),
          const SizedBox(height: FitSpacing.s16),
          for (final day in days) ...[
            FitCard(
              variant: FitCardVariant.clickable,
              selected: day.isToday,
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => PlanosWorkoutDetailPage(plan: plan, day: day),
                ),
              ),
              padding: const EdgeInsets.all(FitSpacing.s12),
              child: Row(
                children: [
                  const SizedBox.square(
                    dimension: FitLayout.domainThumbnailSmall,
                    child: PlanosPlanMedia(
                      compact: true,
                      height: FitLayout.domainThumbnailSmall,
                    ),
                  ),
                  const SizedBox(width: FitSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day.weekday,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          day.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          day.subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    day.isToday ? FitIcons.play : FitIcons.check,
                    color: day.isToday
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s8),
          ],
        ],
      ),
    );
  }

  Widget _weekdaySelector(BuildContext context) {
    const labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: FitSpacing.s4,
      runSpacing: FitSpacing.s8,
      children: [
        for (final label in labels)
          FitChip(label: label, selected: label == 'Qui', onSelected: (_) {}),
      ],
    );
  }
}

/// PLAN-015. Detalhe de um treino dentro do plano.
class PlanosWorkoutDetailPage extends StatelessWidget {
  const PlanosWorkoutDetailPage({
    super.key,
    required this.plan,
    required this.day,
  });

  final TreinoModel plan;
  final PlanosPlanDayView day;

  @override
  Widget build(BuildContext context) {
    final exercises = _exercisesFor(plan, day);
    return PlanosOfficialPage(
      title: day.name,
      subtitle:
          '${exercises.length} exercicios  |  ${plan.tempoEstimado}-${plan.tempoEstimado + 10} min',
      onBack: () => Navigator.of(context).maybePop(),
      bottomAction: FitPrimaryButton(
        label: 'Comecar treino',
        icon: FitIcons.play,
        fullWidth: true,
        onPressed: () => _startWorkout(context),
      ),
      child: ListView(
        padding: const EdgeInsets.all(FitSpacing.s16),
        children: [
          const FitChip(label: 'Exercicios', selected: true),
          const SizedBox(height: FitSpacing.s16),
          FitInfoCard(
            title: 'Dica FitIA',
            description:
                'Mantenha o foco na execucao e aumente progressivamente as cargas.',
            icon: FitIcons.ai,
          ),
          const SizedBox(height: FitSpacing.s16),
          for (var index = 0; index < exercises.length; index++) ...[
            _exerciseRow(context, exercises[index], index),
            const SizedBox(height: FitSpacing.s8),
          ],
        ],
      ),
    );
  }

  Widget _exerciseRow(
    BuildContext context,
    ExercicioModel exercise,
    int index,
  ) {
    return FitCard(
      variant: FitCardVariant.clickable,
      onTap: () {},
      padding: const EdgeInsets.all(FitSpacing.s12),
      child: Row(
        children: [
          Text('${index + 1}', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(width: FitSpacing.s12),
          SizedBox.square(
            dimension: FitLayout.domainThumbnailSmall,
            child: PlanosPlanMedia(
              assetPath: exercise.imagem,
              compact: true,
              height: FitLayout.domainThumbnailSmall,
              label: exercise.nome,
            ),
          ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.nome,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  exercise.categoria,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${exercise.series}x ${exercise.repeticoes}  |  ${exercise.descansoSegundos}s',
                ),
              ],
            ),
          ),
          const Icon(FitIcons.forward),
        ],
      ),
    );
  }

  void _startWorkout(BuildContext context) {
    final data = buildPlanDays(plan).firstWhere(
      (item) => item.code == day.code && item.index == day.order - 1,
      orElse: () => buildPlanDays(plan).first,
    );
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkoutPreviewPage(plan: plan, day: data),
      ),
    );
  }
}

/// PLAN-016. Edicao leve que persiste apenas os campos expostos pela arte.
class PlanosEditPlanPage extends StatefulWidget {
  const PlanosEditPlanPage({super.key, required this.plan});

  final TreinoModel plan;

  @override
  State<PlanosEditPlanPage> createState() => _PlanosEditPlanPageState();
}

class _PlanosEditPlanPageState extends State<PlanosEditPlanPage> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.plan.nome,
  );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlanosOfficialPage(
      title: 'Editar plano',
      onBack: () => Navigator.of(context).maybePop(),
      actions: [TextButton(onPressed: _save, child: const Text('Salvar'))],
      child: ListView(
        padding: const EdgeInsets.all(FitSpacing.s16),
        children: [
          const PlanosPlanMedia(label: 'Imagem do plano'),
          const SizedBox(height: FitSpacing.s16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nome do plano'),
          ),
          const SizedBox(height: FitSpacing.s16),
          FitSectionCard(
            title: 'Configuracoes',
            child: Column(
              children: [
                _detail('Objetivo', widget.plan.objetivo),
                _detail('Divisao', widget.plan.divisao),
                _detail('Dias por semana', '${_dayCount(widget.plan)} dias'),
                _detail('Duracao', '${widget.plan.tempoEstimado} min'),
                _detail('Nivel', widget.plan.nivel),
              ],
            ),
          ),
          const SizedBox(height: FitSpacing.s16),
          FitSectionCard(
            title: 'Treinos',
            child: Column(
              children: [
                for (final day in _days(widget.plan))
                  _detail(day.name, '${day.exerciseIds.length} exercicios'),
                const SizedBox(height: FitSpacing.s8),
                const FitGhostButton(
                  label: 'Adicionar treino',
                  icon: FitIcons.add,
                ),
              ],
            ),
          ),
          const SizedBox(height: FitSpacing.s16),
          Text('Mais opcoes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: FitSpacing.s8),
          _moreOptions(context),
        ],
      ),
    );
  }

  Widget _detail(String title, String value) {
    return PlanosNavigationRow(title: title, trailing: Text(value));
  }

  Widget _moreOptions(BuildContext context) {
    return FitCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          PlanosNavigationRow(
            title: 'Duplicar plano',
            leading: const Icon(FitIcons.share),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => PlanosDuplicatePage(plan: widget.plan),
              ),
            ),
          ),
          PlanosNavigationRow(
            title: 'Exportar',
            leading: const Icon(FitIcons.share),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => PlanosImportSharePage(plan: widget.plan),
              ),
            ),
          ),
          PlanosNavigationRow(
            title: 'Excluir plano',
            leading: const Icon(FitIcons.delete),
            destructive: true,
            onTap: _confirmDelete,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final updated = _copyPlan(widget.plan, name: name);
    await TreinoService.instance.adicionarTreinoComPersistencia(updated);
    if (mounted) Navigator.of(context).pop(updated);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir plano?'),
        content: const Text('Esta acao nao pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    TreinoService.instance.removerTreino(widget.plan.id);
    Navigator.of(context).pop();
  }
}

/// PLAN-017. Resumo estatistico sem alterar o historico existente.
class PlanosStatisticsPage extends StatelessWidget {
  const PlanosStatisticsPage({
    super.key,
    required this.plan,
    required this.progress,
  });

  final TreinoModel plan;
  final PlanProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    return PlanosOfficialPage(
      title: 'Progresso',
      onBack: () => Navigator.of(context).maybePop(),
      bottomAction: FitPrimaryButton(
        label: 'Ver historico completo',
        fullWidth: true,
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const PlanosHistoryPage()),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(FitSpacing.s16),
        children: [
          Wrap(
            spacing: FitSpacing.s8,
            children: const [
              FitChip(label: 'Plano', selected: true),
              FitChip(label: 'Semana'),
              FitChip(label: 'Mes'),
            ],
          ),
          const SizedBox(height: FitSpacing.s16),
          FitCard(
            title: 'Progresso geral',
            child: Row(
              children: [
                const Icon(FitIcons.workout, size: FitLayout.iconSizeLarge),
                const Spacer(),
                FitCircularProgress(
                  value: progress.weeklyProgress,
                  showPercentage: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: FitSpacing.s16),
          const PlanosMetricRow(
            metrics: [
              PlanosMetricData(
                label: 'Treinos',
                value: '18 / 24',
                icon: FitIcons.workout,
              ),
              PlanosMetricData(
                label: 'Exercicios',
                value: '132 / 160',
                icon: FitIcons.exercise,
              ),
              PlanosMetricData(
                label: 'Tempo',
                value: '18h 42m',
                icon: FitIcons.time,
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s24),
          Text(
            'Volume por semana',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: FitSpacing.s12),
          const _PlanosBarChart(),
          const SizedBox(height: FitSpacing.s24),
          Text(
            'Musculos mais treinados',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: FitSpacing.s8),
          for (final item in const [
            ('Peito', '92%'),
            ('Costas', '86%'),
            ('Pernas', '85%'),
          ])
            PlanosNavigationRow(title: item.$1, trailing: Text(item.$2)),
        ],
      ),
    );
  }
}

/// PLAN-020. Importacao e compartilhamento sem criar contrato inexistente.
class PlanosImportSharePage extends StatefulWidget {
  const PlanosImportSharePage({super.key, this.plan});

  final TreinoModel? plan;

  @override
  State<PlanosImportSharePage> createState() => _PlanosImportSharePageState();
}

class _PlanosImportSharePageState extends State<PlanosImportSharePage> {
  final _controller = TextEditingController();
  var _mode = 'Link';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlanosOfficialPage(
      title: widget.plan == null
          ? 'Importar plano'
          : 'Importar ou compartilhar',
      onBack: () => Navigator.of(context).maybePop(),
      child: ListView(
        padding: const EdgeInsets.all(FitSpacing.s16),
        children: [
          Wrap(
            children: ['Link', 'Arquivo', 'Manual']
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: FitSpacing.s8),
                    child: FitChip(
                      label: item,
                      selected: _mode == item,
                      onSelected: (_) => setState(() => _mode = item),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: FitSpacing.s24),
          Text(
            'Cole o link do plano',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: FitSpacing.s8),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'https://...'),
          ),
          const SizedBox(height: FitSpacing.s12),
          FitPrimaryButton(
            label: 'Importar',
            fullWidth: true,
            onPressed: _showUnavailable,
          ),
          const SizedBox(height: FitSpacing.s24),
          Text(
            'Plataformas suportadas',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: FitSpacing.s12),
          const Wrap(
            spacing: FitSpacing.s8,
            runSpacing: FitSpacing.s8,
            children: [
              FitTag(label: 'Hevy'),
              FitTag(label: 'Strong'),
              FitTag(label: 'FitNotes'),
              FitTag(label: 'Google Sheets'),
            ],
          ),
          if (widget.plan != null) ...[
            const SizedBox(height: FitSpacing.s24),
            Text(
              'Ou compartilhe o seu',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: FitSpacing.s12),
            FitCard(
              child: Column(
                children: [
                  Text(
                    'FITIA-7HG4K2',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ShareIcon(icon: Icons.copy_outlined, label: 'Copiar'),
                      _ShareIcon(
                        icon: Icons.message_outlined,
                        label: 'WhatsApp',
                      ),
                      _ShareIcon(
                        icon: Icons.camera_alt_outlined,
                        label: 'Instagram',
                      ),
                      _ShareIcon(icon: FitIcons.more, label: 'Mais'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'A importacao sera habilitada quando houver uma fonte compativel.',
        ),
      ),
    );
  }
}

/// PLAN-021. Calendario e lembretes locais de plano.
class PlanosCalendarPage extends StatefulWidget {
  const PlanosCalendarPage({super.key, this.plan});

  final TreinoModel? plan;

  @override
  State<PlanosCalendarPage> createState() => _PlanosCalendarPageState();
}

class _PlanosCalendarPageState extends State<PlanosCalendarPage> {
  var _reminders = true;

  @override
  Widget build(BuildContext context) {
    return PlanosOfficialPage(
      title: 'Calendario',
      onBack: () => Navigator.of(context).maybePop(),
      child: ListView(
        padding: const EdgeInsets.all(FitSpacing.s16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(FitIcons.back),
              Text('Junho 2026', style: Theme.of(context).textTheme.titleLarge),
              const Icon(FitIcons.forward),
            ],
          ),
          const SizedBox(height: FitSpacing.s16),
          const _PlanosMonthGrid(),
          const SizedBox(height: FitSpacing.s16),
          FitCard(
            title: 'Proximo treino',
            child: Row(
              children: [
                const Icon(FitIcons.workout),
                const SizedBox(width: FitSpacing.s12),
                Expanded(child: Text(widget.plan?.nome ?? 'Upper B')),
                FitOutlinedButton(
                  label: 'Iniciar',
                  size: FitButtonSize.small,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: FitSpacing.s12),
          FitCard(
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lembretes de treino'),
              subtitle: const Text('19:00 - Segunda, Terca, Quinta, Sexta'),
              value: _reminders,
              onChanged: (value) => setState(() => _reminders = value),
            ),
          ),
        ],
      ),
    );
  }
}

/// PLAN-022. Comparacao informativa entre duas estruturas de plano.
class PlanosComparePage extends StatelessWidget {
  const PlanosComparePage({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Frequencia', '4 dias', '6 dias'),
      ('Volume', '20 exerc.', '36 exerc.'),
      ('Tempo/treino', '50-60 min', '60-75 min'),
      ('Nivel', 'Intermediario', 'Intermediario'),
      ('Avaliacao', '4.9', '4.8'),
    ];
    return PlanosOfficialPage(
      title: 'Comparar planos',
      onBack: () => Navigator.of(context).maybePop(),
      bottomAction: FitPrimaryButton(
        label: 'Escolher PPL',
        fullWidth: true,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      child: ListView(
        padding: const EdgeInsets.all(FitSpacing.s16),
        children: [
          Row(
            children: const [
              Expanded(
                child: _CompareHeader(
                  title: 'Upper/Lower',
                  subtitle: '4 dias\n8 semanas',
                  selected: false,
                ),
              ),
              SizedBox(width: FitSpacing.s12),
              Expanded(
                child: _CompareHeader(
                  title: 'PPL',
                  subtitle: '6 dias\n12 semanas',
                  selected: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s24),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: FitSpacing.s8),
              child: Row(
                children: [
                  Expanded(child: Text(row.$1)),
                  Expanded(child: Text(row.$2, textAlign: TextAlign.center)),
                  Expanded(child: Text(row.$3, textAlign: TextAlign.end)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// PLAN-023. Historico preservando o armazenamento existente de planos.
class PlanosHistoryPage extends StatelessWidget {
  const PlanosHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PlanosOfficialPage(
      title: 'Meu historico',
      onBack: () => Navigator.of(context).maybePop(),
      child: ListView(
        padding: const EdgeInsets.all(FitSpacing.s16),
        children: [
          const Wrap(
            spacing: FitSpacing.s8,
            children: [
              FitChip(label: 'Concluidos', selected: true),
              FitChip(label: 'Todos'),
            ],
          ),
          const SizedBox(height: FitSpacing.s16),
          for (final item in const [
            ('Upper / Lower', '8 semanas - 2026'),
            ('Definicao', '6 semanas - 2026'),
            ('PPL', '9 semanas - 2025'),
            ('Bulking Clean', '12 semanas - 2025'),
          ]) ...[
            FitCard(
              child: Row(
                children: [
                  const Icon(FitIcons.success),
                  const SizedBox(width: FitSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Text('Concluido'),
                        Text(
                          item.$2,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s8),
          ],
          const PlanosMetricRow(
            metrics: [
              PlanosMetricData(
                label: 'Planos concluidos',
                value: '6',
                icon: FitIcons.success,
              ),
              PlanosMetricData(
                label: 'Semanas treinando',
                value: '32',
                icon: FitIcons.calendar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// PLAN-024. Duplicacao conectada ao armazenamento de planos.
class PlanosDuplicatePage extends StatefulWidget {
  const PlanosDuplicatePage({super.key, required this.plan});

  final TreinoModel plan;

  @override
  State<PlanosDuplicatePage> createState() => _PlanosDuplicatePageState();
}

class _PlanosDuplicatePageState extends State<PlanosDuplicatePage> {
  late final TextEditingController _name = TextEditingController(
    text: '${widget.plan.nome} (copia)',
  );
  var _copyProgress = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlanosOfficialPage(
      title: 'Duplicar plano',
      onBack: () => Navigator.of(context).maybePop(),
      bottomAction: FitLoadingButton(
        label: 'Duplicar plano',
        loading: false,
        icon: FitIcons.share,
        fullWidth: true,
        onPressed: _duplicate,
      ),
      child: ListView(
        padding: const EdgeInsets.all(FitSpacing.s16),
        children: [
          FitPlanCard(
            name: widget.plan.nome,
            objective: '${_dayCount(widget.plan)} dias por semana',
          ),
          const SizedBox(height: FitSpacing.s24),
          Text('Novo plano', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: FitSpacing.s8),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nome do novo plano'),
          ),
          const SizedBox(height: FitSpacing.s16),
          Text(
            'O que deseja copiar?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: FitSpacing.s8),
          for (final item in const [
            ('Exercicios e treinos', true),
            ('Series, repeticoes e descanso', true),
            ('Cargas e pesos', true),
            ('Progresso do plano', false),
            ('Observacoes e anotacoes', true),
          ])
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(item.$1),
              subtitle: const Text('Copiar informacoes do plano atual'),
              value: item.$2 || _copyProgress,
              onChanged: item.$1.startsWith('Progresso')
                  ? (value) => setState(() => _copyProgress = value)
                  : null,
            ),
          const SizedBox(height: FitSpacing.s16),
          const FitInfoCard(
            title: 'Dica FitIA',
            description:
                'A duplicacao cria uma copia completa. Voce podera editar tudo depois.',
            icon: FitIcons.ai,
          ),
        ],
      ),
    );
  }

  Future<void> _duplicate() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    await TreinoService.instance.adicionarTreinoComPersistencia(
      _copyPlan(
        widget.plan,
        id: 'plan_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }
}

/// PLAN-025. Visual de arquivos; o status persistido ainda nao existe no modelo.
class PlanosArchivePage extends StatelessWidget {
  const PlanosArchivePage({super.key, this.plan});

  final TreinoModel? plan;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Upper / Lower V1', 'Arquivado em 12/05/2024', 'Arquivado'),
      ('Bulking Clean', 'Arquivado em 03/03/2024', 'Arquivado'),
      ('Definicao 8 Semanas', 'Finalizado em 20/02/2024', 'Finalizado'),
      ('Iniciante Academia', 'Finalizado em 15/01/2024', 'Finalizado'),
    ];
    return PlanosOfficialPage(
      title: 'Arquivos de planos',
      onBack: () => Navigator.of(context).maybePop(),
      child: ListView(
        padding: const EdgeInsets.all(FitSpacing.s16),
        children: [
          const Wrap(
            spacing: FitSpacing.s8,
            children: [
              FitChip(label: 'Ativos'),
              FitChip(label: 'Arquivados', selected: true),
              FitChip(label: 'Finalizados'),
            ],
          ),
          const SizedBox(height: FitSpacing.s16),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Buscar planos arquivados...',
            ),
          ),
          const SizedBox(height: FitSpacing.s16),
          for (final item in items) ...[
            FitCard(
              child: Row(
                children: [
                  const Icon(FitIcons.archive),
                  const SizedBox(width: FitSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          item.$2,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  FitTag(label: item.$3),
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s8),
          ],
          const SizedBox(height: FitSpacing.s16),
          const FitInfoCard(
            title: 'Arquivamento pendente',
            description:
                'O modelo atual ainda nao persiste o status de arquivo. Esta lista representa o destino visual previsto.',
            icon: FitIcons.info,
          ),
        ],
      ),
    );
  }
}

class _PlanosBarChart extends StatelessWidget {
  const _PlanosBarChart();

  @override
  Widget build(BuildContext context) {
    const values = [0.32, 0.48, 0.6, 0.78, 0.93, 0.56, 0.83, 1.0];
    return SizedBox(
      height: FitLayout.domainChartHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final value in values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s4),
                child: FractionallySizedBox(
                  heightFactor: value,
                  alignment: Alignment.bottomCenter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: FitRadius.smallBorder,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanosMonthGrid extends StatelessWidget {
  const _PlanosMonthGrid();

  @override
  Widget build(BuildContext context) {
    const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
    const dates = [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28,
      29,
      30,
    ];
    return Column(
      children: [
        Row(
          children: [
            for (final day in weekdays)
              Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
          ],
        ),
        const SizedBox(height: FitSpacing.s8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: FitSpacing.s8,
            crossAxisSpacing: FitSpacing.s8,
          ),
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final active = const {9, 15, 18}.contains(dates[index]);
            return DecoratedBox(
              decoration: BoxDecoration(
                color: active
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(child: Text('${dates[index]}')),
            );
          },
        ),
      ],
    );
  }
}

class _CompareHeader extends StatelessWidget {
  const _CompareHeader({
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      selected: selected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PlanosPlanMedia(compact: true, height: FitSpacing.s64),
          const SizedBox(height: FitSpacing.s8),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ShareIcon extends StatelessWidget {
  const _ShareIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: FitSpacing.s4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

enum _PlanAction {
  edit,
  statistics,
  calendar,
  duplicate,
  share,
  archive,
  delete,
}

class PlanosPlanDayView {
  const PlanosPlanDayView({
    required this.code,
    required this.name,
    required this.weekday,
    required this.order,
    required this.exerciseIds,
    this.isToday = false,
  });

  final String code;
  final String name;
  final String weekday;
  final int order;
  final List<String> exerciseIds;
  final bool isToday;

  String get subtitle => 'Peito, Costas, Ombros';
}

List<PlanosPlanDayView> _days(TreinoModel plan) {
  final source = plan.planoDias.isEmpty
      ? [
          TreinoDiaModel(
            codigo: 'A',
            nome: plan.nome,
            ordem: 1,
            exercicioIds: plan.exercicios.map((item) => item.id).toList(),
          ),
        ]
      : plan.planoDias;
  const weekdays = ['Segunda', 'Terca', 'Quinta', 'Sexta', 'Sabado', 'Domingo'];
  return [
    for (var index = 0; index < source.length; index++)
      PlanosPlanDayView(
        code: source[index].codigo,
        name: source[index].nome,
        weekday: weekdays[index % weekdays.length],
        order: source[index].ordem,
        exerciseIds: source[index].exercicioIds,
        isToday: index == source.length - 1,
      ),
  ];
}

List<ExercicioModel> _exercisesFor(TreinoModel plan, PlanosPlanDayView day) {
  final ids = day.exerciseIds.toSet();
  final exercises = ids.isEmpty
      ? plan.exercicios
      : plan.exercicios
            .where(
              (exercise) =>
                  ids.contains(exercise.id) || ids.contains(exercise.nome),
            )
            .toList();
  return exercises.isEmpty ? plan.exercicios : exercises;
}

int _dayCount(TreinoModel plan) =>
    plan.planoDias.isEmpty ? plan.diasPorSemana : plan.planoDias.length;

String? _imageFor(TreinoModel plan) {
  if (plan.exercicios.isEmpty) return null;
  final asset = plan.exercicios.first.imagem.trim();
  return asset.isEmpty ? null : asset;
}

TreinoModel _copyPlan(TreinoModel source, {String? id, String? name}) {
  return TreinoModel(
    id: id ?? source.id,
    nome: name ?? source.nome,
    descricao: source.descricao,
    objetivo: source.objetivo,
    nivel: source.nivel,
    divisao: source.divisao,
    tempoEstimado: source.tempoEstimado,
    diasPorSemana: source.diasPorSemana,
    local: source.local,
    equipamentos: source.equipamentos,
    gruposPrioritarios: source.gruposPrioritarios,
    lesoesRestricoes: source.lesoesRestricoes,
    exerciciosFavoritos: source.exerciciosFavoritos,
    exerciciosEvitados: source.exerciciosEvitados,
    observacoes: source.observacoes,
    diaPlano: source.diaPlano,
    grupoDia: source.grupoDia,
    ordemDia: source.ordemDia,
    planoDias: source.planoDias,
    criadoPorIA: source.criadoPorIA,
    exercicios: source.exercicios,
    dataCriacao: DateTime.now().toIso8601String(),
    origem: source.origem,
    readyPlanId: source.readyPlanId,
  );
}
