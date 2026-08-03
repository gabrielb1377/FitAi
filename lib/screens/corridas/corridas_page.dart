import 'dart:async';

import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';
import '../../models/coach_insight_model.dart';
import '../../models/corrida_model.dart';
import '../../services/coach_insight_service.dart';
import '../../services/running_session_service.dart';
import '../perfil/widgets/coach_insights_card.dart';
import '../widgets/activities/activities_navigation_header.dart';
import '../widgets/activities/activity_page_entrance.dart';
import '../widgets/activities/activity_stats_grid.dart';
import '../widgets/activities/running_session_overview.dart';
import 'historico_corridas_page.dart';

class CorridasPage extends StatefulWidget {
  final RunningSessionService? runningService;

  const CorridasPage({super.key, this.runningService});

  @override
  State<CorridasPage> createState() => _CorridasPageState();
}

class _CorridasPageState extends State<CorridasPage> {
  late final RunningSessionService _running;
  late Future<List<CoachInsightModel>> _coachFuture;
  var _loading = true;
  var _hasError = false;

  @override
  void initState() {
    super.initState();
    _running = widget.runningService ?? RunningSessionService.instance;
    _coachFuture = const CoachInsightService().gerarInsightsPorTipo('corrida');
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await _running.initialize();
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

  void _start() => unawaited(_running.start());
  void _pause() => unawaited(_running.pause());
  void _resume() => unawaited(_running.resume());

  Future<void> _finish() async {
    CorridaModel? run;
    try {
      run = await _running.finish();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A finalização ficou salva localmente para tentar novamente.',
            ),
          ),
        );
      }
      return;
    }
    if (!mounted || run == null) return;
    setState(() {
      _coachFuture = const CoachInsightService().gerarInsightsPorTipo(
        'corrida',
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Corrida salva no historico.')),
    );
  }

  Future<void> _cancel() async {
    final shouldDiscard = await FitConfirmDialog.show(
      context: context,
      title: 'Cancelar corrida?',
      message: 'Os dados desta sessão ainda não serão salvos no histórico.',
      confirmLabel: 'Cancelar corrida',
      cancelLabel: 'Continuar corrida',
      isDestructive: true,
    );
    if (shouldDiscard != true) return;

    await _running.discardActiveSession();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Corrida cancelada.')));
  }

  Future<void> _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoricoCorridasPage()),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _state(const FitListSkeleton(itemCount: 4));
    if (_hasError) {
      return _state(
        FitErrorState(
          title: 'Corridas indisponiveis',
          error: 'Nao foi possivel restaurar sua sessao de corrida.',
          onRetry: _initialize,
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ActivityPageEntrance(
          child: ListView(
            key: const PageStorageKey('corridas-scroll'),
            padding: const EdgeInsets.fromLTRB(
              FitSpacing.s20,
              FitSpacing.s12,
              FitSpacing.s20,
              FitSpacing.s64 + FitSpacing.s32 + FitSpacing.s4,
            ),
            physics: const BouncingScrollPhysics(),
            children: [
              ListenableBuilder(
                listenable: _running,
                builder: (context, _) => Column(
                  children: [
                    ActivitiesNavigationHeader(
                      title: 'Corridas',
                      subtitle: _headerSubtitle,
                      trailing: _running.isFinalizing
                          ? const FitBadge(
                              label: 'Salvando',
                              tone: FitBadgeTone.info,
                              icon: Icons.sync_rounded,
                            )
                          : _running.hasActiveSession
                          ? const FitBadge(
                              label: 'Ao vivo',
                              tone: FitBadgeTone.danger,
                              icon: Icons.fiber_manual_record_rounded,
                            )
                          : null,
                    ),
                    const SizedBox(height: FitSpacing.s24),
                    RunningSessionOverview(
                      distanceKm: _running.distanceKm,
                      elapsedSeconds: _running.elapsedSeconds,
                      averageSpeed: _running.averageSpeed,
                      currentSpeed: _running.currentSpeed,
                      pace: _running.pace,
                      isActive: _running.hasActiveSession,
                      isPaused: _running.isPaused,
                      isFinalizing: _running.isFinalizing,
                      gpsConnected: _running.gpsConnected,
                      onStart: _start,
                      onPause: _pause,
                      onResume: _resume,
                      onFinish: _finish,
                      onCancel: _cancel,
                    ),
                    const SizedBox(height: FitSpacing.s24),
                    ActivityStatsGrid(
                      items: [
                        ActivityStat(
                          label: 'Tempo',
                          value: _formatTime(_running.elapsedSeconds),
                          icon: Icons.timer_outlined,
                        ),
                        ActivityStat(
                          label: 'Vel. media',
                          value:
                              '${_running.averageSpeed.toStringAsFixed(1)} km/h',
                          icon: Icons.speed_outlined,
                        ),
                        ActivityStat(
                          label: 'Vel. atual',
                          value:
                              '${_running.currentSpeed.toStringAsFixed(1)} km/h',
                          icon: Icons.bolt_rounded,
                        ),
                        ActivityStat(
                          label: 'Pace',
                          value: _formatPace(_running.pace),
                          icon: Icons.route_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FitSpacing.s24),
              _buildCoach(),
              const SizedBox(height: FitSpacing.s24),
              FitButton(
                label: 'Ver historico',
                icon: Icons.history_rounded,
                onPressed: _openHistory,
                variant: FitButtonVariant.outlined,
                expand: true,
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
              title: 'Corridas',
              subtitle: 'Inicie, acompanhe ou retome sua corrida.',
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildCoach() {
    return FutureBuilder<List<CoachInsightModel>>(
      future: _coachFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const FitListSkeleton(itemCount: 1, itemHeight: 96);
        }
        return CoachInsightsCard(
          insights: (snapshot.data ?? const <CoachInsightModel>[])
              .take(3)
              .toList(),
        );
      },
    );
  }

  String get _headerSubtitle {
    if (_running.isFinalizing) {
      return 'Finalização protegida localmente.';
    }
    if (_running.isPaused) return 'Corrida pausada. Retome quando quiser.';
    if (_running.hasActiveSession) {
      return _running.gpsConnected
          ? 'GPS conectado.'
          : 'Buscando sinal de GPS.';
    }
    return 'Inicie, acompanhe ou retome sua corrida.';
  }

  static String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    return '${minutes.toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  static String _formatPace(double pace) {
    if (pace <= 0) return '--';
    final seconds = (pace * 60).round();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} min/km';
  }
}
