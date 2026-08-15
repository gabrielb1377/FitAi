import 'dart:async';

import 'package:flutter/material.dart';

import '../design_system/fit_design_system.dart';
import '../features/activities/presentation/pages/activities_calendar_page.dart';
import '../features/activities/presentation/pages/activities_timeline_page.dart';
import '../models/corrida_model.dart';
import '../services/running_session_service.dart';
import '../services/steps_service.dart';
import '../services/storage_service.dart';
import 'corridas/corridas_page.dart';
import 'passos_page.dart';
import 'widgets/activities/activities_hub_data.dart';
import 'widgets/activities/activities_hub_content.dart';
import 'widgets/activities/activities_hub_state.dart';
import 'widgets/activities/recent_activity.dart';

class AtividadesPage extends StatefulWidget {
  final int passos;
  final double distancia;
  final double velocidadeMedia;
  final int segundos;
  final bool corridaIniciada;
  final VoidCallback iniciarCorrida;
  final VoidCallback pararCorrida;

  const AtividadesPage({
    super.key,
    required this.passos,
    required this.distancia,
    required this.velocidadeMedia,
    required this.segundos,
    required this.corridaIniciada,
    required this.iniciarCorrida,
    required this.pararCorrida,
  });

  @override
  State<AtividadesPage> createState() => _AtividadesPageState();
}

class _AtividadesPageState extends State<AtividadesPage> {
  final _running = RunningSessionService.instance;
  final _steps = StepsService.instance;
  late Future<ActivitiesHubData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
    _running.addListener(_refreshView);
    _steps.addListener(_refreshView);
    unawaited(_running.initialize());
    unawaited(_steps.initialize());
  }

  @override
  void dispose() {
    _running.removeListener(_refreshView);
    _steps.removeListener(_refreshView);
    super.dispose();
  }

  void _refreshView() {
    if (mounted) setState(() {});
  }

  Future<ActivitiesHubData> _loadData() async {
    final runs = await StorageService.carregarCorridas();
    runs.sort((a, b) => _runDate(b).compareTo(_runDate(a)));
    return ActivitiesHubData(runs: runs);
  }

  Future<void> _reload() async {
    final next = _loadData();
    if (mounted) {
      setState(() {
        _dataFuture = next;
      });
    }
    await next;
  }

  Future<void> _openRuns() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CorridasPage()),
    );
    if (mounted) await _reload();
  }

  Future<void> _openSteps() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PassosPage(passos: _stepsToday)),
    );
    if (mounted) await _reload();
  }

  Future<void> _openTimeline() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ActivitiesTimelinePage()),
    );
    if (mounted) await _reload();
  }

  Future<void> _openCalendar() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ActivitiesCalendarPage()),
    );
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_running, _steps]),
      builder: (context, _) => FutureBuilder<ActivitiesHubData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError && !snapshot.hasData) {
            return ActivitiesHubState(
              content: FitErrorState(
                title: 'Atividades indisponiveis',
                error: 'Nao foi possivel carregar seus dados locais.',
                onRetry: _reload,
              ),
            );
          }
          return _buildOverview(
            data: snapshot.data ?? const ActivitiesHubData.empty(),
          );
        },
      ),
    );
  }

  Widget _buildOverview({required ActivitiesHubData data}) {
    final runsToday = data.runs
        .where((run) => _isToday(_runDate(run)))
        .toList();
    final runDistance = runsToday.fold<double>(
      0,
      (sum, run) => sum + run.distancia,
    );
    final runSeconds = runsToday.fold<int>(0, (sum, run) => sum + run.segundos);
    final activeSeconds = runSeconds + _running.elapsedSeconds;
    final distanceToday = runDistance + _running.distanceKm;
    final latestRun = data.runs.isEmpty ? null : data.runs.first;

    return ActivitiesHubContent(
      steps: '$_stepsToday',
      distance: '${distanceToday.toStringAsFixed(2)} km',
      activeTime: _formatDuration(activeSeconds),
      showLocalBanner: _showLocalBanner,
      runSubtitle: latestRun == null
          ? 'Sua proxima corrida comeca aqui.'
          : 'Ultima corrida ${_formatDate(_runDate(latestRun))}',
      runDistance: latestRun == null
          ? '--'
          : '${latestRun.distancia.toStringAsFixed(2)} km',
      runPace: latestRun == null ? '--' : _formatPace(latestRun.pace),
      stepsGoal: '$_stepsGoal',
      stepsProgress: _stepsProgress,
      onOpenRuns: _openRuns,
      onOpenSteps: _openSteps,
      onOpenTimeline: _openTimeline,
      onOpenCalendar: _openCalendar,
      onRefresh: _reload,
      recentItems: [
        RecentActivityItem(
          icon: Icons.directions_run_rounded,
          title: 'Ultima corrida',
          subtitle: latestRun == null
              ? 'Nenhuma corrida registrada.'
              : '${latestRun.distancia.toStringAsFixed(2)} km em ${_formatDuration(latestRun.segundos)}',
        ),
        RecentActivityItem(
          icon: Icons.sync_rounded,
          title: 'Ultima sincronizacao',
          subtitle: _lastSyncLabel,
        ),
        RecentActivityItem(
          icon: Icons.directions_walk_rounded,
          title: 'Passos de hoje',
          subtitle: '$_stepsToday de $_stepsGoal passos.',
        ),
      ],
    );
  }

  int get _stepsToday => _steps.initialized ? _steps.stepsToday : widget.passos;
  int get _stepsGoal => _steps.initialized ? _steps.dailyGoal : 10000;
  double get _stepsProgress => _steps.initialized
      ? _steps.progressToday
      : (_stepsToday / _stepsGoal).clamp(0.0, 1.0);
  bool get _showLocalBanner => _steps.initialized && !_steps.usingHealthConnect;
  String get _lastSyncLabel {
    final syncedAt = _steps.initialized ? _steps.today.syncedAt : null;
    return syncedAt == null ? 'Dados locais ativos.' : _formatDate(syncedAt);
  }

  static bool _isToday(DateTime value) {
    final now = DateTime.now();
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  static DateTime _runDate(CorridaModel run) =>
      DateTime.tryParse(run.endTime ?? run.data) ??
      DateTime.tryParse(run.data) ??
      DateTime(0);

  static String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }

  static String _formatPace(double pace) {
    if (pace <= 0) return '--';
    final seconds = (pace * 60).round();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} min/km';
  }

  static String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
}
