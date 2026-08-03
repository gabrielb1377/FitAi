import 'dart:async';

import 'package:flutter/material.dart';

import '../design_system/fit_design_system.dart';
import '../features/activities/domain/steps_metrics.dart';
import '../models/daily_steps_model.dart';
import '../services/steps_service.dart';
import 'widgets/activities/activities_navigation_header.dart';
import 'widgets/activities/activity_page_entrance.dart';
import 'widgets/activities/steps_calendar_card.dart';
import 'widgets/activities/steps_daily_overview.dart';
import 'widgets/activities/steps_goal_editor.dart';
import 'widgets/activities/steps_history_section.dart';
import 'widgets/activities/steps_period_overview.dart';

enum _StepsPeriod { week, month }

class PassosPage extends StatefulWidget {
  const PassosPage({
    super.key,
    required this.passos,
    this.stepsService,
    this.initialDate,
  });

  final int passos;
  final StepsService? stepsService;
  final DateTime? initialDate;

  @override
  State<PassosPage> createState() => _PassosPageState();
}

class _PassosPageState extends State<PassosPage> {
  late final StepsService _steps;
  var _loading = true;
  var _hasError = false;
  var _period = _StepsPeriod.week;
  late DateTime _calendarMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _steps = widget.stepsService ?? StepsService.instance;
    final now = widget.initialDate ?? DateTime.now();
    _calendarMonth = DateTime(now.year, now.month);
    _selectedDate = now;
    _steps.addListener(_onStepsChanged);
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _steps.removeListener(_onStepsChanged);
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await _steps.initialize();
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  void _onStepsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    try {
      await _steps.refreshLocal();
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _editGoal() async {
    final goal = await FitBottomSheet.show<int>(
      context: context,
      title: 'Meta diária',
      subtitle: 'Sua meta anterior permanece nos dias já registrados.',
      isScrollControlled: true,
      child: StepsGoalEditor(
        initialGoal: _steps.dailyGoal,
        onSave: (value) => Navigator.of(context).pop(value),
      ),
    );
    if (goal == null) return;
    try {
      await _steps.updateDailyGoal(goal);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Meta diária atualizada.')));
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message?.toString() ?? 'Meta inválida.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _state(const FitListSkeleton(itemCount: 4));
    if (_hasError) {
      return _state(
        FitErrorState(
          title: 'Passos indisponíveis',
          error: 'Não foi possível carregar os dados locais de passos.',
          onRetry: _initialize,
        ),
      );
    }
    return _content(context);
  }

  Widget _content(BuildContext context) {
    final records = _recordsForPeriod;
    final summary = StepsMetrics.summarize(
      records,
      from: _periodStart,
      to: DateTime.now(),
    );
    final source = _steps.todayRecord?.sourceLabel;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ActivityPageEntrance(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              key: const PageStorageKey('passos-scroll'),
              padding: const EdgeInsets.fromLTRB(
                FitSpacing.s20,
                FitSpacing.s12,
                FitSpacing.s20,
                FitSpacing.s64 + FitSpacing.s32 + FitSpacing.s4,
              ),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                ActivitiesNavigationHeader(
                  title: 'Passos',
                  subtitle: source ?? 'Acompanhe seu resumo diário.',
                  trailing: source == null
                      ? null
                      : FitBadge(
                          label: _sourceBadgeLabel,
                          tone: _steps.usesSeedData
                              ? FitBadgeTone.warning
                              : FitBadgeTone.neutral,
                        ),
                ),
                const SizedBox(height: FitSpacing.s24),
                StepsDailyOverview(
                  record: _steps.todayRecord,
                  goal: _steps.dailyGoal,
                  status: _steps.statusMessage,
                  onEditGoal: _editGoal,
                ),
                if (_steps.isOffline) ...[
                  const SizedBox(height: FitSpacing.s16),
                  FitOfflineState(
                    compact: true,
                    title: 'Sincronização pendente',
                    description:
                        'Os registros continuam seguros neste dispositivo.',
                    retryLabel: 'Tentar sincronizar',
                    onRetry: () => unawaited(_steps.syncNow()),
                  ),
                ],
                if (_steps.usesSeedData) ...[
                  const SizedBox(height: FitSpacing.s16),
                  const _SeedDataNotice(),
                ],
                const SizedBox(height: FitSpacing.s24),
                _PeriodSelector(
                  selected: _period,
                  onChanged: (period) => setState(() => _period = period),
                ),
                const SizedBox(height: FitSpacing.s12),
                StepsPeriodOverview(
                  title: _period == _StepsPeriod.week
                      ? 'Visão semanal'
                      : 'Visão mensal',
                  summary: summary,
                  streak: _steps.activeStreak,
                  streakDataAvailable: _steps.streak.hasCompleteData,
                  comparisonWithYesterday: _steps.comparisonWithYesterday,
                  comparisonDataAvailable: _steps.dayComparison.hasCompleteData,
                ),
                const SizedBox(height: FitSpacing.s16),
                StepsPeriodChart(
                  records: records,
                  title: _period == _StepsPeriod.week
                      ? 'Passos por dia'
                      : 'Passos no mês',
                ),
                const SizedBox(height: FitSpacing.s24),
                StepsCalendarCard(
                  month: _calendarMonth,
                  records: _steps.history,
                  selectedDate: _selectedDate,
                  onPreviousMonth: () => setState(() {
                    _calendarMonth = DateTime(
                      _calendarMonth.year,
                      _calendarMonth.month - 1,
                    );
                  }),
                  onNextMonth: () => setState(() {
                    _calendarMonth = DateTime(
                      _calendarMonth.year,
                      _calendarMonth.month + 1,
                    );
                  }),
                  onSelectDate: (date) => setState(() => _selectedDate = date),
                ),
                const SizedBox(height: FitSpacing.s24),
                StepsHistorySection(
                  records: records,
                  periodLabel: _period == _StepsPeriod.week
                      ? 'Últimos 7 dias'
                      : 'Últimos 30 dias',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _state(Widget content) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ActivitiesNavigationHeader(
              title: 'Passos',
              subtitle: 'Acompanhe seu resumo diário.',
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  List<DailyStepsModel> get _recordsForPeriod =>
      _steps.recordsForLastDays(_period == _StepsPeriod.week ? 7 : 30);

  DateTime get _periodStart => DateTime.now().subtract(
    Duration(days: _period == _StepsPeriod.week ? 6 : 29),
  );

  String get _sourceBadgeLabel => _steps.usesSeedData ? 'Seed' : 'Fonte local';
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final _StepsPeriod selected;
  final ValueChanged<_StepsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Período do histórico de passos',
      child: Wrap(
        spacing: FitSpacing.s8,
        children: [
          FitChip(
            label: 'Semana',
            selected: selected == _StepsPeriod.week,
            onSelected: (_) => onChanged(_StepsPeriod.week),
          ),
          FitChip(
            label: 'Mês',
            selected: selected == _StepsPeriod.month,
            onSelected: (_) => onChanged(_StepsPeriod.month),
          ),
        ],
      ),
    );
  }
}

class _SeedDataNotice extends StatelessWidget {
  const _SeedDataNotice();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Dados de demonstração ativos somente no modo de desenvolvimento.',
      child: Text(
        'Dados de demonstração ativos somente no modo de desenvolvimento.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
