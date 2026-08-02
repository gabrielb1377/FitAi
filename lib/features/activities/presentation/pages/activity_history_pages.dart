import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../domain/activity_history_models.dart';
import '../controllers/activities_history_controller.dart';
import '../routes/activities_routes.dart';
import '../widgets/activity_history_widgets.dart';

class ActivitiesTimelinePage extends StatelessWidget {
  const ActivitiesTimelinePage({
    super.key,
    required this.loadHistory,
    this.source,
    this.title = 'Historico',
    this.autofocusSearch = false,
    this.clock,
  });

  final ActivitiesHistoryLoader loadHistory;
  final Listenable? source;
  final String title;
  final bool autofocusSearch;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) => ActivitiesHistoryHost(
    loadHistory: loadHistory,
    source: source,
    clock: clock,
    builder: (context, history) => Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FitHeader(
              title: title,
              showBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
              actions: [
                FitIconButton(
                  icon: FitIcons.calendar,
                  tooltip: 'Abrir calendario',
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(ActivitiesRoutes.calendar),
                ),
              ],
            ),
            Expanded(
              child: _TimelineBody(
                history: history,
                autofocusSearch: autofocusSearch,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ActivitiesSearchPage extends StatelessWidget {
  const ActivitiesSearchPage({
    super.key,
    required this.loadHistory,
    this.source,
    this.clock,
  });

  final ActivitiesHistoryLoader loadHistory;
  final Listenable? source;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) => ActivitiesTimelinePage(
    loadHistory: loadHistory,
    source: source,
    title: 'Pesquisar atividades',
    autofocusSearch: true,
    clock: clock,
  );
}

class _TimelineBody extends StatelessWidget {
  const _TimelineBody({required this.history, required this.autofocusSearch});

  final ActivitiesHistoryController history;
  final bool autofocusSearch;

  @override
  Widget build(BuildContext context) {
    if (history.isLoading && !history.hasData) {
      return const ActivityHistorySkeleton();
    }
    if (history.errorMessage != null && !history.hasData) {
      return FitErrorState(
        error: history.errorMessage!,
        onRetry: history.refresh,
      );
    }
    final workouts = history.filteredWorkouts;
    final prSessions = history.snapshot.personalRecords
        .map((record) => record.sessionId)
        .toSet();
    return RefreshIndicator(
      onRefresh: history.refresh,
      child: ListView.separated(
        key: const PageStorageKey('activities-history-scroll'),
        padding: const EdgeInsets.fromLTRB(
          FitSpacing.s20,
          FitSpacing.s8,
          FitSpacing.s20,
          FitSpacing.s64,
        ),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: workouts.isEmpty ? 2 : workouts.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: FitSpacing.s12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ActivitySearchInput(
                  controller: history,
                  autofocus: autofocusSearch,
                ),
                const SizedBox(height: FitSpacing.s12),
                ActivityPeriodFilters(
                  controller: history,
                  onOpenFilters: () =>
                      ActivityFilterSheet.show(context, history),
                ),
                if (history.isShowingCachedOfflineData) ...[
                  const SizedBox(height: FitSpacing.s16),
                  FitOfflineState(
                    compact: true,
                    title: 'Dados locais disponiveis',
                    description: 'Algumas atividades aguardam sincronizacao.',
                    onRetry: history.refresh,
                  ),
                ],
              ],
            );
          }
          if (workouts.isEmpty) {
            return SizedBox(
              height: MediaQuery.sizeOf(context).height / 2,
              child: FitEmptyState(
                icon: FitIcons.search,
                title: 'Nenhuma atividade encontrada',
                description:
                    'Ajuste a busca ou os filtros para ver seu historico.',
                actionLabel: 'Limpar filtros',
                onAction: () {
                  history.setQuery('');
                  history.clearFilters();
                },
              ),
            );
          }
          final workout = workouts[index - 1];
          return ActivityTimelineCard(
            workout: workout,
            hasPersonalRecord: prSessions.contains(workout.id),
            onTap: () => Navigator.of(
              context,
            ).pushNamed(ActivitiesRoutes.detail, arguments: workout.id),
          );
        },
      ),
    );
  }
}

class ActivitiesCalendarPage extends StatefulWidget {
  const ActivitiesCalendarPage({
    super.key,
    required this.loadHistory,
    this.source,
    this.clock,
  });

  final ActivitiesHistoryLoader loadHistory;
  final Listenable? source;
  final DateTime Function()? clock;

  @override
  State<ActivitiesCalendarPage> createState() => _ActivitiesCalendarPageState();
}

class _ActivitiesCalendarPageState extends State<ActivitiesCalendarPage> {
  DateTime _referenceDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) => ActivitiesHistoryHost(
    loadHistory: widget.loadHistory,
    source: widget.source,
    clock: widget.clock,
    builder: (context, history) => Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FitHeader(
              title: 'Calendario',
              showBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
              actions: [
                FitIconButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Mes anterior',
                  onPressed: () => setState(() {
                    _referenceDate = DateTime(
                      _referenceDate.year,
                      _referenceDate.month - 1,
                    );
                  }),
                ),
                FitIconButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Proximo mes',
                  onPressed: () => setState(() {
                    _referenceDate = DateTime(
                      _referenceDate.year,
                      _referenceDate.month + 1,
                    );
                  }),
                ),
              ],
            ),
            Expanded(
              child: _CalendarBody(
                history: history,
                referenceDate: _referenceDate,
                selectedDate: _selectedDate,
                onSelected: (value) => setState(() => _selectedDate = value),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody({
    required this.history,
    required this.referenceDate,
    required this.selectedDate,
    required this.onSelected,
  });

  final ActivitiesHistoryController history;
  final DateTime referenceDate;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    if (history.isLoading && !history.hasData) {
      return const ActivityHistorySkeleton(itemCount: 5);
    }
    if (history.errorMessage != null && !history.hasData) {
      return FitErrorState(
        error: history.errorMessage!,
        onRetry: history.refresh,
      );
    }
    final selectedWorkouts = history.snapshot.workouts
        .where((workout) => _isSameDay(workout.finishedAt, selectedDate))
        .toList(growable: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FitSpacing.s20,
        FitSpacing.s8,
        FitSpacing.s20,
        FitSpacing.s64,
      ),
      children: [
        Text(
          _monthTitle(referenceDate),
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: FitSpacing.s16),
        FitCard(
          variant: FitCardVariant.outlined,
          padding: const EdgeInsets.all(FitSpacing.s12),
          child: ActivityCalendarGrid(
            entries: history.snapshot.calendar,
            selectedDate: selectedDate,
            referenceDate: referenceDate,
            onSelected: onSelected,
          ),
        ),
        const SizedBox(height: FitSpacing.s24),
        FitSection(
          title: formatActivityDate(selectedDate),
          subtitle: '${selectedWorkouts.length} treinos registrados',
          padding: EdgeInsets.zero,
          child: selectedWorkouts.isEmpty
              ? const FitEmptyState(
                  icon: FitIcons.calendar,
                  title: 'Nenhuma atividade neste dia',
                  description:
                      'Quando voce concluir um treino, ele aparecera aqui.',
                )
              : Column(
                  children: [
                    for (final workout in selectedWorkouts) ...[
                      ActivityTimelineCard(
                        workout: workout,
                        hasPersonalRecord: history.snapshot.personalRecords.any(
                          (record) => record.sessionId == workout.id,
                        ),
                        onTap: () => Navigator.of(context).pushNamed(
                          ActivitiesRoutes.detail,
                          arguments: workout.id,
                        ),
                      ),
                      if (workout != selectedWorkouts.last)
                        const SizedBox(height: FitSpacing.s12),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class ActivityWorkoutDetailPage extends StatelessWidget {
  const ActivityWorkoutDetailPage({
    super.key,
    required this.sessionId,
    required this.loadHistory,
    this.source,
    this.clock,
  });

  final String sessionId;
  final ActivitiesHistoryLoader loadHistory;
  final Listenable? source;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) => ActivitiesHistoryHost(
    loadHistory: loadHistory,
    source: source,
    clock: clock,
    builder: (context, history) {
      if (history.isLoading && !history.hasData) {
        return const Scaffold(body: SafeArea(child: ActivityHistorySkeleton()));
      }
      final workout = history.workoutById(sessionId);
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              FitHeader(
                title: 'Detalhes da atividade',
                showBackButton: true,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: workout == null
                    ? FitEmptyState(
                        icon: FitIcons.history,
                        title: 'Atividade indisponivel',
                        description:
                            history.errorMessage ??
                            'Este treino nao esta salvo neste dispositivo.',
                        actionLabel: 'Voltar ao historico',
                        onAction: () => Navigator.of(context).maybePop(),
                      )
                    : _WorkoutDetailBody(workout: workout),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _WorkoutDetailBody extends StatelessWidget {
  const _WorkoutDetailBody({required this.workout});

  final WorkoutHistory workout;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      FitSpacing.s20,
      FitSpacing.s8,
      FitSpacing.s20,
      FitSpacing.s64,
    ),
    children: [
      FitCard(
        title: workout.summary.title,
        subtitle: workout.planName ?? 'Treino concluido',
        leading: Icon(
          FitIcons.workout,
          color: Theme.of(context).colorScheme.primary,
        ),
        trailing: activitySyncStatusChip(workout.syncStatus),
        variant: FitCardVariant.outlined,
        child: Text(
          formatActivityDateTime(workout.finishedAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      const SizedBox(height: FitSpacing.s16),
      _DetailMetrics(workout: workout),
      const SizedBox(height: FitSpacing.s24),
      FitSection(
        title: 'Exercicios executados',
        subtitle:
            '${workout.metrics.exerciseCount} exercicios e ${workout.metrics.setCount} series',
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final exercise in workout.exercises) ...[
              _ExerciseHistoryCard(exercise: exercise),
              if (exercise != workout.exercises.last)
                const SizedBox(height: FitSpacing.s12),
            ],
          ],
        ),
      ),
    ],
  );
}

class _DetailMetrics extends StatelessWidget {
  const _DetailMetrics({required this.workout});

  final WorkoutHistory workout;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        label: 'Duracao',
        value: formatActivityDuration(workout.metrics.duration),
        icon: FitIcons.time,
      ),
      (
        label: 'Volume',
        value: formatActivityVolume(workout.metrics.totalVolume),
        icon: FitIcons.weight,
      ),
      (
        label: 'Series',
        value: '${workout.metrics.setCount}',
        icon: FitIcons.repetitions,
      ),
      (
        label: 'Repeticoes',
        value: '${workout.metrics.totalRepetitions}',
        icon: FitIcons.repetitions,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= FitBreakpoints.tablet ? 4 : 2;
        final width =
            (constraints.maxWidth - FitSpacing.s12 * (columns - 1)) / columns;
        return Wrap(
          spacing: FitSpacing.s12,
          runSpacing: FitSpacing.s12,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: FitMetricCard(
                  label: metric.label,
                  value: metric.value,
                  icon: metric.icon,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ExerciseHistoryCard extends StatelessWidget {
  const _ExerciseHistoryCard({required this.exercise});

  final ExerciseHistory exercise;

  @override
  Widget build(BuildContext context) => FitCard(
    title: exercise.name,
    subtitle: exercise.muscles.isEmpty
        ? exercise.category
        : exercise.muscles.join(' - '),
    variant: FitCardVariant.outlined,
    child: Column(
      children: [
        for (final set in exercise.sets) ...[
          Semantics(
            label:
                'Serie ${set.index + 1}: ${set.weight.toStringAsFixed(0)} kg por ${set.repetitions} repeticoes',
            child: Wrap(
              spacing: FitSpacing.s12,
              runSpacing: FitSpacing.s4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Serie ${set.index + 1}'),
                Text(
                  '${set.weight.toStringAsFixed(0)} kg x ${set.repetitions}',
                ),
                if (set.restSeconds != null)
                  Text(
                    '${set.restSeconds}s',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (set != exercise.sets.last)
            const FitDivider(verticalSpacing: FitSpacing.s8),
        ],
        if (exercise.notes?.isNotEmpty == true) ...[
          const FitDivider(verticalSpacing: FitSpacing.s12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              exercise.notes!.join(' '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
    ),
  );
}

bool _isSameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

String _monthTitle(DateTime value) {
  const months = [
    'Janeiro',
    'Fevereiro',
    'Marco',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return '${months[value.month - 1]} de ${value.year}';
}
