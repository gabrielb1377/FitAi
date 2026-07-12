import 'dart:async';

import 'package:flutter/material.dart';

import '../design_system/fit_design_system.dart';
import '../services/steps_service.dart';
import 'widgets/activities/activities_navigation_header.dart';
import 'widgets/activities/activity_page_entrance.dart';
import 'widgets/activities/activity_stats_grid.dart';
import 'widgets/activities/local_data_banner.dart';
import 'widgets/activities/steps_daily_overview.dart';

class PassosPage extends StatefulWidget {
  final int passos;

  const PassosPage({super.key, required this.passos});

  @override
  State<PassosPage> createState() => _PassosPageState();
}

class _PassosPageState extends State<PassosPage> {
  final _steps = StepsService.instance;
  var _loading = true;
  var _hasError = false;

  @override
  void initState() {
    super.initState();
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
      if (mounted) {
        setState(() => _loading = false);
      }
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

  void _sync() => unawaited(_steps.syncNow(requestPermission: true));

  @override
  Widget build(BuildContext context) {
    if (_loading) return _state(const FitListSkeleton(itemCount: 3));
    if (_hasError) {
      return _state(
        FitErrorState(
          title: 'Passos indisponiveis',
          error: 'Nao foi possivel carregar seus dados de passos.',
          onRetry: _initialize,
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ActivityPageEntrance(
          child: ListView(
            key: const PageStorageKey('passos-scroll'),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            physics: const BouncingScrollPhysics(),
            children: [
              ActivitiesNavigationHeader(
                title: 'Passos',
                subtitle: _statusMeta,
                trailing: _steps.usingHealthConnect
                    ? const FitBadge(
                        label: 'Health Connect',
                        tone: FitBadgeTone.success,
                        icon: Icons.favorite_outline_rounded,
                      )
                    : null,
              ),
              const SizedBox(height: FitSpacing.s24),
              StepsDailyOverview(
                steps: _stepsToday,
                goal: _stepsGoal,
                progress: _stepsProgress,
                status: _statusMeta,
                sourceMessage: _steps.statusMessage,
                isSyncing: _steps.syncing,
                onSync: _sync,
              ),
              if (!_steps.usingHealthConnect) ...[
                const SizedBox(height: FitSpacing.s20),
                const LocalDataBanner(),
              ],
              const SizedBox(height: FitSpacing.s24),
              ActivityStatsGrid(
                items: [
                  ActivityStat(
                    label: 'Calorias',
                    value:
                        '${_steps.estimatedCalories.toStringAsFixed(0)} kcal',
                    icon: Icons.local_fire_department_outlined,
                  ),
                  ActivityStat(
                    label: 'Distancia',
                    value:
                        '${_steps.estimatedDistanceKm.toStringAsFixed(2)} km',
                    icon: Icons.route_outlined,
                  ),
                  ActivityStat(
                    label: 'Media semanal',
                    value: '${_steps.weeklyAverage}',
                    icon: Icons.query_stats_rounded,
                  ),
                  ActivityStat(
                    label: 'Melhor dia',
                    value: _steps.bestDayThisWeek == null
                        ? '--'
                        : '${_steps.bestDayThisWeek!.steps}',
                    icon: Icons.emoji_events_outlined,
                  ),
                ],
              ),
            ],
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
              subtitle: 'Acompanhe sua meta e sincronize seus passos.',
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  int get _stepsToday =>
      _steps.initialized ? _steps.stepsToday : widget.passos.clamp(0, 1000000);
  int get _stepsGoal => _steps.dailyGoal;
  double get _stepsProgress => _steps.initialized
      ? _steps.progressToday
      : (_stepsToday / _stepsGoal).clamp(0.0, 1.0);
  String get _statusMeta => _stepsToday >= _stepsGoal
      ? 'Meta atingida!'
      : '${(_stepsGoal - _stepsToday).clamp(0, _stepsGoal)} passos para a meta';
}
