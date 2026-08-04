import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

import '../../../progression/progression.dart';

enum _XpHistoryFilter { all, workouts, runs, steps, achievements }

/// Historico local de XP com filtros simples por origem de dominio.
class ProfileXpHistoryPage extends StatefulWidget {
  const ProfileXpHistoryPage({super.key, required this.snapshot});

  final ProgressionSnapshot snapshot;

  @override
  State<ProfileXpHistoryPage> createState() => _ProfileXpHistoryPageState();
}

class _ProfileXpHistoryPageState extends State<ProfileXpHistoryPage> {
  var _filter = _XpHistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final events = widget.snapshot.recentEvents
        .where((event) => _matches(event, _filter))
        .toList(growable: false);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            FitHeader(
              title: 'Historico de XP',
              subtitle: 'Progresso salvo neste dispositivo.',
              showBackButton: true,
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in _XpHistoryFilter.values) ...[
                        FitChip(
                          label: _filterLabel(filter),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                        const SizedBox(width: FitSpacing.s8),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: FitSpacing.s12),
            Expanded(
              child: events.isEmpty
                  ? const FitEmptyState(
                      icon: FitIcons.history,
                      title: 'Sem eventos nesta categoria',
                      description:
                          'As acoes concluidas aparecerao aqui automaticamente.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        FitSpacing.s20,
                        FitSpacing.s4,
                        FitSpacing.s20,
                        FitSpacing.s32,
                      ),
                      itemCount: events.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: FitSpacing.s8),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return FitCard(
                          semanticLabel:
                              '${event.reason}, mais ${event.amount} XP',
                          child: FitHorizontalMetric(
                            label: event.reason,
                            value: '+${event.amount} XP',
                            detail:
                                '${_dateLabel(event.createdAt)} - ${_syncLabel(event.syncStatus)}',
                            icon: _iconFor(event.sourceType),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matches(XpEvent event, _XpHistoryFilter filter) => switch (filter) {
    _XpHistoryFilter.all => true,
    _XpHistoryFilter.workouts => event.sourceType == XpSourceType.workout,
    _XpHistoryFilter.runs => event.sourceType == XpSourceType.running,
    _XpHistoryFilter.steps => event.sourceType == XpSourceType.stepsGoal,
    _XpHistoryFilter.achievements =>
      event.sourceType == XpSourceType.achievement,
  };

  String _filterLabel(_XpHistoryFilter filter) => switch (filter) {
    _XpHistoryFilter.all => 'Todos',
    _XpHistoryFilter.workouts => 'Treinos',
    _XpHistoryFilter.runs => 'Corridas',
    _XpHistoryFilter.steps => 'Passos',
    _XpHistoryFilter.achievements => 'Conquistas',
  };

  IconData _iconFor(XpSourceType source) => switch (source) {
    XpSourceType.workout => FitIcons.workout,
    XpSourceType.running => FitIcons.running,
    XpSourceType.stepsGoal => FitIcons.steps,
    XpSourceType.achievement => FitIcons.achievement,
  };

  String _syncLabel(ProgressionSyncStatus status) => switch (status) {
    ProgressionSyncStatus.local => 'Salvo localmente',
    ProgressionSyncStatus.pending => 'Aguardando sincronizacao',
    ProgressionSyncStatus.synced => 'Sincronizado',
    ProgressionSyncStatus.failed => 'Sincronizacao pendente',
  };

  String _dateLabel(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
  }
}
