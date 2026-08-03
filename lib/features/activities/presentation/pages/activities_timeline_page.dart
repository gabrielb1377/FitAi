import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../screens/corridas/corrida_detalhe_page.dart';
import '../../../../screens/passos_page.dart';
import '../../../../screens/widgets/activities/activities_navigation_header.dart';
import '../../../../screens/widgets/activities/activity_page_entrance.dart';
import '../../data/activities_timeline_repository.dart';
import '../../domain/activity_query.dart';
import '../../domain/activity_record.dart';

class ActivitiesTimelinePage extends StatefulWidget {
  const ActivitiesTimelinePage({
    super.key,
    this.repository = const ActivitiesTimelineRepository(),
  });

  final ActivitiesTimelineRepository repository;

  @override
  State<ActivitiesTimelinePage> createState() => _ActivitiesTimelinePageState();
}

class _ActivitiesTimelinePageState extends State<ActivitiesTimelinePage> {
  final _scrollController = ScrollController();
  var _filter = ActivityTimelineFilter.all;
  var _items = const <ActivityTimelineItem>[];
  ActivityTimelineCursor? _cursor;
  var _loading = true;
  var _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _reload();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || _cursor == null) {
      return;
    }
    if (_scrollController.position.extentAfter < FitLayout.domainChartHeight) {
      _loadMore();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
      _cursor = null;
      _items = const [];
    });
    try {
      final page = await widget.repository.loadTimeline(filter: _filter);
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _cursor = page.nextCursor;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    final cursor = _cursor;
    if (cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.repository.loadTimeline(
        filter: _filter,
        cursor: cursor,
      );
      if (!mounted) return;
      final existing = _items.map((item) => item.id).toSet();
      setState(() {
        _items = [
          ..._items,
          ...page.items.where((item) => existing.add(item.id)),
        ];
        _cursor = page.nextCursor;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _changeFilter(ActivityTimelineFilter value) {
    if (value == _filter) return;
    setState(() => _filter = value);
    _reload();
  }

  Future<void> _openItem(ActivityTimelineItem item) async {
    final record = item.record;
    if (record.type == ActivityType.running) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CorridaDetalhePorIdPage(runId: record.id),
        ),
      );
    } else if (record.type == ActivityType.steps) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PassosPage(passos: 0, initialDate: item.occurredAt),
        ),
      );
    }
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ActivityPageEntrance(
          child: CustomScrollView(
            controller: _scrollController,
            key: const PageStorageKey('activities-timeline-scroll'),
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    FitSpacing.s20,
                    FitSpacing.s12,
                    FitSpacing.s20,
                    FitSpacing.s16,
                  ),
                  child: ActivitiesNavigationHeader(
                    title: 'Linha do tempo',
                    subtitle: 'Corridas e resumos diarios de passos.',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FitSpacing.s20,
                  ),
                  child: _TimelineFilters(
                    selected: _filter,
                    onChanged: _changeFilter,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: FitSpacing.s16)),
              if (_loading)
                const SliverToBoxAdapter(child: FitListSkeleton(itemCount: 4))
              else if (_error != null && _items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: FitErrorState(
                    title: 'Timeline indisponivel',
                    error: 'Nao foi possivel consultar os dados locais.',
                    onRetry: _reload,
                  ),
                )
              else if (_items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: FitActivityEmptyState(
                    title: 'Nenhuma atividade encontrada',
                    description:
                        'Corridas finalizadas e passos disponiveis aparecerao aqui.',
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    FitSpacing.s20,
                    FitLayout.none,
                    FitSpacing.s20,
                    FitSpacing.s16,
                  ),
                  sliver: SliverList.separated(
                    itemCount: _items.length,
                    itemBuilder: (context, index) => _TimelineRow(
                      item: _items[index],
                      onTap: () => _openItem(_items[index]),
                    ),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: FitSpacing.s12),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      FitSpacing.s20,
                      FitLayout.none,
                      FitSpacing.s20,
                      FitSpacing.s32,
                    ),
                    child: _TimelineFooter(
                      hasMore: _cursor != null,
                      loading: _loadingMore,
                      hasError: _error != null,
                      onRetry: _loadMore,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineFilters extends StatelessWidget {
  const _TimelineFilters({required this.selected, required this.onChanged});

  final ActivityTimelineFilter selected;
  final ValueChanged<ActivityTimelineFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Filtrar linha do tempo por tipo de atividade',
      child: Wrap(
        spacing: FitSpacing.s8,
        runSpacing: FitSpacing.s8,
        children: [
          _FilterChip(
            label: 'Todos',
            selected: selected == ActivityTimelineFilter.all,
            onSelected: () => onChanged(ActivityTimelineFilter.all),
          ),
          _FilterChip(
            label: 'Corridas',
            selected: selected == ActivityTimelineFilter.runs,
            onSelected: () => onChanged(ActivityTimelineFilter.runs),
          ),
          _FilterChip(
            label: 'Passos',
            selected: selected == ActivityTimelineFilter.steps,
            onSelected: () => onChanged(ActivityTimelineFilter.steps),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => FitChip(
    label: label,
    selected: selected,
    onSelected: (_) => onSelected(),
  );
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.onTap});

  final ActivityTimelineItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = item.record.details;
    final isRun = item.record.type == ActivityType.running;
    final title = isRun ? 'Corrida' : 'Passos';
    final subtitle = isRun
        ? '${_dateTime(item.occurredAt)} - ${_runDetails(details)}'
        : '${_dateTime(item.occurredAt)} - ${_stepsDetails(details)}';
    return FitCard(
      variant: FitCardVariant.clickable,
      onTap: onTap,
      semanticLabel: '$title. $subtitle. ${_syncLabel(item.record.syncStatus)}',
      leading: Icon(isRun ? FitIcons.running : FitIcons.steps),
      title: title,
      subtitle: subtitle,
      trailing: FitBadge(
        label: _syncLabel(item.record.syncStatus),
        tone: _syncTone(item.record.syncStatus),
      ),
      child: const SizedBox(),
    );
  }

  static String _runDetails(ActivityDetails details) {
    final run = details as RunningActivityDetails;
    final pace = run.paceMinutesPerKm == null
        ? 'ritmo indisponivel'
        : '${run.paceMinutesPerKm!.toStringAsFixed(1)} min/km';
    return '${run.distanceKm.toStringAsFixed(2)} km, $pace';
  }

  static String _stepsDetails(ActivityDetails details) {
    final steps = details as StepsActivityDetails;
    if (steps.goal <= 0) return '${steps.steps} passos, meta indisponivel';
    final percent = ((steps.steps / steps.goal) * 100).clamp(0, 100).round();
    return '${steps.steps} de ${steps.goal} passos, $percent%';
  }

  static String _dateTime(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  static String _syncLabel(ActivitySyncStatus status) => switch (status) {
    ActivitySyncStatus.synced => 'Sincronizado',
    ActivitySyncStatus.queued || ActivitySyncStatus.syncing => 'Pendente',
    ActivitySyncStatus.failed || ActivitySyncStatus.conflict => 'Local',
    ActivitySyncStatus.local => 'Local',
  };

  static FitBadgeTone _syncTone(ActivitySyncStatus status) =>
      status == ActivitySyncStatus.queued ||
          status == ActivitySyncStatus.syncing
      ? FitBadgeTone.warning
      : FitBadgeTone.neutral;
}

class _TimelineFooter extends StatelessWidget {
  const _TimelineFooter({
    required this.hasMore,
    required this.loading,
    required this.hasError,
    required this.onRetry,
  });

  final bool hasMore;
  final bool loading;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: FitCircularLoading());
    if (hasError) {
      return FitOutlinedButton(label: 'Tentar novamente', onPressed: onRetry);
    }
    if (!hasMore) {
      return Text(
        'Fim das atividades disponiveis neste dispositivo.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return const SizedBox.shrink();
  }
}
