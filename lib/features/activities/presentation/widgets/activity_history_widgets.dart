import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../domain/activity_history_models.dart';
import '../../../workout_vertical_slice/domain/workout_vertical_models.dart';
import '../controllers/activities_history_controller.dart';

typedef ActivitiesHistoryViewBuilder =
    Widget Function(
      BuildContext context,
      ActivitiesHistoryController controller,
    );

/// Mantem o controlador visual ligado somente a fonte canonica do historico.
class ActivitiesHistoryHost extends StatefulWidget {
  const ActivitiesHistoryHost({
    super.key,
    required this.loadHistory,
    required this.builder,
    this.source,
    this.clock,
  });

  final ActivitiesHistoryLoader loadHistory;
  final Listenable? source;
  final DateTime Function()? clock;
  final ActivitiesHistoryViewBuilder builder;

  @override
  State<ActivitiesHistoryHost> createState() => _ActivitiesHistoryHostState();
}

class _ActivitiesHistoryHostState extends State<ActivitiesHistoryHost> {
  late ActivitiesHistoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ActivitiesHistoryController(
      loadHistory: widget.loadHistory,
      clock: widget.clock,
    );
    widget.source?.addListener(_refreshFromSource);
    _controller.refresh();
  }

  @override
  void didUpdateWidget(covariant ActivitiesHistoryHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.source, widget.source)) {
      oldWidget.source?.removeListener(_refreshFromSource);
      widget.source?.addListener(_refreshFromSource);
    }
  }

  void _refreshFromSource() {
    if (mounted) _controller.refresh(preserveError: true);
  }

  @override
  void dispose() {
    widget.source?.removeListener(_refreshFromSource);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => widget.builder(context, _controller),
  );
}

class ActivitySearchInput extends StatefulWidget {
  const ActivitySearchInput({
    super.key,
    required this.controller,
    this.autofocus = false,
  });

  final ActivitiesHistoryController controller;
  final bool autofocus;

  @override
  State<ActivitySearchInput> createState() => _ActivitySearchInputState();
}

class _ActivitySearchInputState extends State<ActivitySearchInput> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.controller.query);
  }

  @override
  void didUpdateWidget(covariant ActivitySearchInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_textController.text != widget.controller.query) {
      _textController.value = _textController.value.copyWith(
        text: widget.controller.query,
        selection: TextSelection.collapsed(
          offset: widget.controller.query.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FitSearchField(
    controller: _textController,
    autofocus: widget.autofocus,
    label: 'Pesquisar atividades',
    hintText: 'Treino, plano, exercicio ou data',
    semanticLabel: 'Pesquisar por treino, plano, exercicio ou data',
    onChanged: widget.controller.setQuery,
    onClear: () => widget.controller.setQuery(''),
  );
}

class ActivityPeriodFilters extends StatelessWidget {
  const ActivityPeriodFilters({
    super.key,
    required this.controller,
    required this.onOpenFilters,
  });

  final ActivitiesHistoryController controller;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final period in ActivityHistoryPeriod.values) ...[
          FitFilterChip(
            label: period.label,
            selected: controller.period == period,
            onSelected: (_) => controller.setPeriod(period),
          ),
          const SizedBox(width: FitSpacing.s8),
        ],
        FitIconButton(
          icon: Icons.tune_rounded,
          tooltip: 'Filtrar atividades',
          variant: FitIconButtonVariant.outlined,
          onPressed: onOpenFilters,
        ),
      ],
    ),
  );
}

class ActivitySummaryGrid extends StatelessWidget {
  const ActivitySummaryGrid({
    super.key,
    required this.workouts,
    required this.streak,
  });

  final List<WorkoutHistory> workouts;
  final WorkoutStreak streak;

  @override
  Widget build(BuildContext context) {
    final duration = workouts.fold<int>(
      0,
      (total, workout) => total + workout.metrics.durationSeconds,
    );
    final volume = workouts.fold<double>(
      0,
      (total, workout) => total + workout.metrics.totalVolume,
    );
    final cards = [
      FitMetricCard(
        label: 'Treinos',
        value: '${workouts.length}',
        icon: FitIcons.activities,
      ),
      FitMetricCard(
        label: 'Duracao',
        value: formatActivityDuration(Duration(seconds: duration)),
        icon: FitIcons.time,
      ),
      FitMetricCard(
        label: 'Volume',
        value: formatActivityVolume(volume),
        icon: FitIcons.weight,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= FitBreakpoints.tablet ? 3 : 3;
        final width =
            (constraints.maxWidth - FitSpacing.s8 * (columns - 1)) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: FitSpacing.s8,
              runSpacing: FitSpacing.s8,
              children: [
                for (final card in cards) SizedBox(width: width, child: card),
              ],
            ),
            const SizedBox(height: FitSpacing.s12),
            Semantics(
              label: 'Sequencia atual de ${streak.currentDays} dias',
              child: FitCard(
                variant: FitCardVariant.outlined,
                padding: const EdgeInsets.all(FitSpacing.s12),
                child: Row(
                  children: [
                    Icon(
                      FitIcons.streak,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(width: FitSpacing.s8),
                    Expanded(
                      child: Text(
                        streak.currentDays > 0
                            ? '${streak.currentDays} dias de sequencia'
                            : 'Comece uma nova sequencia hoje',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      'Melhor: ${streak.longestDays}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ActivityTimelineCard extends StatelessWidget {
  const ActivityTimelineCard({
    super.key,
    required this.workout,
    this.hasPersonalRecord = false,
    this.onTap,
  });

  final WorkoutHistory workout;
  final bool hasPersonalRecord;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => FitCard(
      variant: FitCardVariant.clickable,
      onTap: onTap,
      semanticLabel:
          '${workout.summary.title}, ${formatActivityDate(workout.finishedAt)}',
      padding: const EdgeInsets.all(FitSpacing.s12),
      child: constraints.maxWidth <= FitBreakpoints.mobile
          ? _CompactTimelineCardContent(
              workout: workout,
              hasPersonalRecord: hasPersonalRecord,
            )
          : _RegularTimelineCardContent(
              workout: workout,
              hasPersonalRecord: hasPersonalRecord,
            ),
    ),
  );
}

class _RegularTimelineCardContent extends StatelessWidget {
  const _RegularTimelineCardContent({
    required this.workout,
    required this.hasPersonalRecord,
  });

  final WorkoutHistory workout;
  final bool hasPersonalRecord;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _ActivityDate(workout: workout),
      Icon(FitIcons.workout, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: FitSpacing.s12),
      Expanded(child: _ActivityTimelineCopy(workout: workout)),
      const SizedBox(width: FitSpacing.s8),
      _ActivityStatus(
        status: workout.syncStatus,
        hasPersonalRecord: hasPersonalRecord,
      ),
    ],
  );
}

class _CompactTimelineCardContent extends StatelessWidget {
  const _CompactTimelineCardContent({
    required this.workout,
    required this.hasPersonalRecord,
  });

  final WorkoutHistory workout;
  final bool hasPersonalRecord;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActivityDate(workout: workout),
          Icon(FitIcons.workout, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: FitSpacing.s12),
          Expanded(child: _ActivityTitle(workout: workout)),
        ],
      ),
      const SizedBox(height: FitSpacing.s12),
      _ActivityMetrics(workout: workout),
      const SizedBox(height: FitSpacing.s12),
      Wrap(
        spacing: FitSpacing.s8,
        runSpacing: FitSpacing.s8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          activitySyncStatusChip(workout.syncStatus),
          if (hasPersonalRecord) ...[
            const FitStatusChip(label: 'PR', tone: FitStatusTone.warning),
          ],
          const Icon(FitIcons.forward, size: FitLayout.iconSizeCompact),
        ],
      ),
    ],
  );
}

class _ActivityDate extends StatelessWidget {
  const _ActivityDate({required this.workout});

  final WorkoutHistory workout;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: FitLayout.minimumTouchTarget,
    child: Column(
      children: [
        Text(
          '${workout.finishedAt.day}'.padLeft(2, '0'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          _shortMonth(workout.finishedAt),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    ),
  );
}

class _ActivityTimelineCopy extends StatelessWidget {
  const _ActivityTimelineCopy({required this.workout});

  final WorkoutHistory workout;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _ActivityTitle(workout: workout),
      const SizedBox(height: FitSpacing.s8),
      _ActivityMetrics(workout: workout),
    ],
  );
}

class _ActivityTitle extends StatelessWidget {
  const _ActivityTitle({required this.workout});

  final WorkoutHistory workout;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        workout.summary.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      if ((workout.planName ?? '').trim().isNotEmpty) ...[
        const SizedBox(height: FitSpacing.s2),
        Text(
          workout.planName!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ],
  );
}

class _ActivityMetrics extends StatelessWidget {
  const _ActivityMetrics({required this.workout});

  final WorkoutHistory workout;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: FitSpacing.s8,
    runSpacing: FitSpacing.s4,
    children: [
      _ActivityMeta(
        icon: FitIcons.time,
        label: formatActivityDuration(workout.metrics.duration),
      ),
      _ActivityMeta(
        icon: FitIcons.weight,
        label: formatActivityVolume(workout.metrics.totalVolume),
      ),
      _ActivityMeta(
        icon: FitIcons.repetitions,
        label: '${workout.metrics.setCount} series',
      ),
    ],
  );
}

class _ActivityStatus extends StatelessWidget {
  const _ActivityStatus({
    required this.status,
    required this.hasPersonalRecord,
  });

  final WorkoutSyncStatus status;
  final bool hasPersonalRecord;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      activitySyncStatusChip(status),
      if (hasPersonalRecord) ...[
        const SizedBox(height: FitSpacing.s8),
        const FitStatusChip(label: 'PR', tone: FitStatusTone.warning),
      ],
      const SizedBox(height: FitSpacing.s8),
      const Icon(FitIcons.forward, size: FitLayout.iconSizeCompact),
    ],
  );
}

class _ActivityMeta extends StatelessWidget {
  const _ActivityMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Wrap(
      spacing: FitSpacing.s4,
      runSpacing: FitSpacing.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(
          icon,
          size: FitLayout.iconSizeSmall,
          color: Theme.of(context).colorScheme.primary,
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

class ActivityHistorySkeleton extends StatelessWidget {
  const ActivityHistorySkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(FitSpacing.s20),
    itemCount: itemCount,
    separatorBuilder: (_, _) => const SizedBox(height: FitSpacing.s12),
    itemBuilder: (_, index) => const FitSkeleton(
      height: FitLayout.skeletonListItemHeight,
      borderRadius: FitRadius.largeBorder,
      semanticLabel: 'Carregando atividade',
    ),
  );
}

class ActivityCalendarGrid extends StatelessWidget {
  const ActivityCalendarGrid({
    super.key,
    required this.entries,
    required this.selectedDate,
    required this.onSelected,
    required this.referenceDate,
  });

  final List<CalendarEntry> entries;
  final DateTime selectedDate;
  final DateTime referenceDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(referenceDate.year, referenceDate.month);
    final firstVisible = firstDay.subtract(
      Duration(days: firstDay.weekday - 1),
    );
    final entryByDate = {
      for (final entry in entries) _dayKey(entry.date): entry,
    };
    final cells = List<DateTime>.generate(
      42,
      (index) => firstVisible.add(Duration(days: index)),
      growable: false,
    );
    const labels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    return Column(
      children: [
        Row(
          children: [
            for (final label in labels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: FitSpacing.s8),
        GridView.builder(
          shrinkWrap: true,
          primary: false,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: FitSpacing.s4,
            crossAxisSpacing: FitSpacing.s4,
          ),
          itemCount: cells.length,
          itemBuilder: (context, index) {
            final date = cells[index];
            final entry = entryByDate[_dayKey(date)];
            final isCurrentMonth = date.month == referenceDate.month;
            final selected = _sameDay(date, selectedDate);
            final hasActivity = entry != null && entry.workoutCount > 0;
            final colors = Theme.of(context).colorScheme;
            return Semantics(
              button: true,
              selected: selected,
              label:
                  '${formatActivityDate(date)}. ${entry?.workoutCount ?? 0} treinos.',
              child: Material(
                color: selected
                    ? colors.primaryContainer
                    : hasActivity
                    ? colors.surfaceContainerHighest
                    : Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onSelected(date),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isCurrentMonth
                            ? null
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class ActivityFilterSheet extends StatelessWidget {
  const ActivityFilterSheet({super.key, required this.controller});

  final ActivitiesHistoryController controller;

  static Future<void> show(
    BuildContext context,
    ActivitiesHistoryController controller,
  ) => FitBottomSheet.show<void>(
    context: context,
    title: 'Filtros',
    subtitle: 'Refine seu historico salvo no dispositivo.',
    isScrollControlled: true,
    child: ActivityFilterSheet(controller: controller),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: FitBreakpoints.tablet),
      child: ListView(
        shrinkWrap: true,
        children: [
          _FilterGroup(
            title: 'Plano',
            values: controller.availablePlans,
            selected: controller.planId == null
                ? 'Todos'
                : controller.snapshot.workouts
                      .where((workout) => workout.planId == controller.planId)
                      .map((workout) => workout.planName)
                      .whereType<String>()
                      .firstOrNull,
            onSelected: (value) {
              final workout = controller.snapshot.workouts.firstWhere(
                (item) => item.planName == value,
              );
              controller.updateFilters(nextPlanId: workout.planId);
            },
            onClear: () => controller.updateFilters(clearPlan: true),
          ),
          const SizedBox(height: FitSpacing.s16),
          _FilterGroup(
            title: 'Grupo muscular',
            values: controller.availableMuscles,
            selected: controller.muscle,
            onSelected: (value) => controller.updateFilters(nextMuscle: value),
            onClear: () => controller.updateFilters(clearMuscle: true),
          ),
          const SizedBox(height: FitSpacing.s16),
          _FilterGroup(
            title: 'Tipo',
            values: controller.availableCategories,
            selected: controller.category,
            onSelected: (value) =>
                controller.updateFilters(nextCategory: value),
            onClear: () => controller.updateFilters(clearCategory: true),
          ),
          const SizedBox(height: FitSpacing.s16),
          Wrap(
            spacing: FitSpacing.s8,
            runSpacing: FitSpacing.s8,
            children: [
              FitFilterChip(
                label: 'Pendente de sync',
                selected: controller.onlyOffline,
                onSelected: (selected) =>
                    controller.updateFilters(nextOnlyOffline: selected),
                icon: FitIcons.offline,
              ),
              FitFilterChip(
                label: 'Com PR',
                selected: controller.onlyPersonalRecords,
                onSelected: (selected) =>
                    controller.updateFilters(nextOnlyPersonalRecords: selected),
                icon: FitIcons.achievement,
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s20),
          Row(
            children: [
              Expanded(
                child: FitButton(
                  label: 'Limpar',
                  variant: FitButtonVariant.ghost,
                  onPressed: controller.clearFilters,
                ),
              ),
              const SizedBox(width: FitSpacing.s12),
              Expanded(
                child: FitButton(
                  label: 'Aplicar (${controller.filteredWorkouts.length})',
                  onPressed: () => Navigator.of(context).pop(),
                  expand: true,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({
    required this.title,
    required this.values,
    required this.selected,
    required this.onSelected,
    required this.onClear,
  });

  final String title;
  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: FitSpacing.s8),
      if (values.isEmpty)
        Text(
          'Ainda nao ha dados suficientes neste historico.',
          style: Theme.of(context).textTheme.bodySmall,
        )
      else
        Wrap(
          spacing: FitSpacing.s8,
          runSpacing: FitSpacing.s8,
          children: [
            FitFilterChip(
              label: 'Todos',
              selected: selected == null || selected == 'Todos',
              onSelected: (_) => onClear(),
            ),
            for (final value in values)
              FitFilterChip(
                label: value,
                selected: selected == value,
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
    ],
  );
}

FitStatusChip activitySyncStatusChip(WorkoutSyncStatus status) => FitStatusChip(
  label: switch (status) {
    WorkoutSyncStatus.synced => 'Sincronizado',
    WorkoutSyncStatus.syncing => 'Sincronizando',
    WorkoutSyncStatus.pending || WorkoutSyncStatus.local => 'Local',
    WorkoutSyncStatus.conflict => 'Conflito',
    WorkoutSyncStatus.rejected || WorkoutSyncStatus.failed => 'Falha',
  },
  tone: switch (status) {
    WorkoutSyncStatus.synced => FitStatusTone.success,
    WorkoutSyncStatus.syncing ||
    WorkoutSyncStatus.pending ||
    WorkoutSyncStatus.local => FitStatusTone.neutral,
    WorkoutSyncStatus.conflict ||
    WorkoutSyncStatus.rejected ||
    WorkoutSyncStatus.failed => FitStatusTone.error,
  },
);

String formatActivityDuration(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60);
  if (hours > 0) return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  return '$minutes min';
}

String formatActivityVolume(double value) => value >= 1000
    ? '${(value / 1000).toStringAsFixed(2)}k kg'
    : '${value.toStringAsFixed(0)} kg';

String formatActivityDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String formatActivityDateTime(DateTime value) =>
    '${formatActivityDate(value)} as ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _shortMonth(DateTime value) => const [
  'JAN',
  'FEV',
  'MAR',
  'ABR',
  'MAI',
  'JUN',
  'JUL',
  'AGO',
  'SET',
  'OUT',
  'NOV',
  'DEZ',
][value.month - 1];

DateTime _dayKey(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
