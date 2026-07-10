import 'package:flutter/material.dart';

import '../../models/coach_insight_model.dart';
import '../../services/coach_insight_service.dart';
import '../../services/running_session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';
import '../perfil/widgets/coach_insights_card.dart';
import 'historico_corridas_page.dart';

class CorridasPage extends StatefulWidget {
  final double distancia;
  final double velocidadeMedia;
  final int segundos;
  final bool corridaIniciada;
  final VoidCallback iniciarCorrida;
  final VoidCallback pararCorrida;

  const CorridasPage({
    super.key,
    required this.distancia,
    required this.velocidadeMedia,
    required this.segundos,
    required this.corridaIniciada,
    required this.iniciarCorrida,
    required this.pararCorrida,
  });

  @override
  State<CorridasPage> createState() => _CorridasPageState();
}

class _CorridasPageState extends State<CorridasPage> {
  final runningSession = RunningSessionService.instance;
  late Future<List<CoachInsightModel>> _coachFuture;

  bool get _corridaIniciada => runningSession.hasActiveSession;

  int get _segundos => runningSession.elapsedSeconds;

  double get _distancia => runningSession.distanceKm;

  double get _velocidadeMedia => runningSession.averageSpeed;

  @override
  void initState() {
    super.initState();
    _coachFuture = const CoachInsightService().gerarInsightsPorTipo('corrida');
    runningSession.addListener(_onCorridaAtualizada);
    _inicializarCorrida();
  }

  @override
  void dispose() {
    runningSession.removeListener(_onCorridaAtualizada);
    super.dispose();
  }

  Future<void> _inicializarCorrida() async {
    await runningSession.initialize();

    if (!mounted) return;
    setState(() {});
  }

  void _onCorridaAtualizada() {
    if (!mounted) return;
    setState(() {});
  }

  void _iniciarCorrida() {
    runningSession.start();
  }

  Future<void> _pararCorrida() async {
    final corrida = await runningSession.finish();

    if (!mounted || corrida == null) return;

    setState(() {
      _coachFuture = const CoachInsightService().gerarInsightsPorTipo(
        'corrida',
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Corrida salva no historico.')),
    );
  }

  void _pausarCorrida() {
    runningSession.pause();
  }

  void _retomarCorrida() {
    runningSession.resume();
  }

  String _formatTempo() {
    final h = _segundos ~/ 3600;
    final m = (_segundos % 3600) ~/ 60;
    final s = _segundos % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace() {
    if (runningSession.pace <= 0) return '--';

    final totalSeconds = (runningSession.pace * 60).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')} min/km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SliverToBoxAdapter(child: _buildHeader(context)),

          // â”€â”€ ConteÃºdo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                // Metric principal â€” distÃ¢ncia
                _buildMainMetric(context),
                const SizedBox(height: 16),

                // Stats secundÃ¡rios â€” tempo e velocidade
                _buildSecondaryStats(context),
                const SizedBox(height: 16),

                _buildCoachCard(),
                const SizedBox(height: 32),

                // BotÃ£o principal
                _buildRunButton(context),
                const SizedBox(height: 14),

                // HistÃ³rico
                _buildHistoricoButton(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachCard() {
    return FutureBuilder<List<CoachInsightModel>>(
      future: _coachFuture,
      builder: (context, snapshot) {
        final insights = (snapshot.data ?? const <CoachInsightModel>[])
            .take(3)
            .toList();

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppGradientCard(
            child: LinearProgressIndicator(minHeight: 3),
          );
        }

        return CoachInsightsCard(insights: insights);
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 20,
        20,
        24,
      ),
      child: AppPremiumHeader(
        eyebrow: runningSession.isPaused
            ? "Pausada"
            : _corridaIniciada
            ? (runningSession.gpsConnected ? "GPS conectado" : "Buscando GPS")
            : "Pronto para correr?",
        title: "Corridas",
        subtitle: "Controle tempo, distancia e ritmo em uma experiencia limpa.",
        icon: Icons.directions_run_rounded,
        gradient: _corridaIniciada
            ? AppColors.gradientRun
            : AppColors.gradientPrimary,
        trailing: _corridaIniciada ? const _LiveBadge() : null,
      ),
    );
  }

  Widget _buildMainMetric(BuildContext context) {
    return AppGradientCard(
      gradient: _corridaIniciada
          ? AppColors.gradientRun
          : AppColors.gradientCard,
      child: Column(
        children: [
          Text(
            'DISTÃ‚NCIA',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _corridaIniciada ? Colors.white60 : null,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _distancia.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  color: _corridaIniciada
                      ? Colors.white
                      : AppColors.textPrimary,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 6),
                child: Text(
                  'km',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _corridaIniciada
                        ? Colors.white60
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStats(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildStatCard(
                context,
                label: 'TEMPO',
                value: _formatTempo(),
                icon: Icons.timer_outlined,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildStatCard(
                context,
                label: 'VEL. MEDIA',
                value: '${_velocidadeMedia.toStringAsFixed(1)} km/h',
                icon: Icons.speed_outlined,
                iconColor: AppColors.accent2,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildStatCard(
                context,
                label: 'VEL. ATUAL',
                value: '${runningSession.currentSpeed.toStringAsFixed(1)} km/h',
                icon: Icons.bolt_rounded,
                iconColor: AppColors.primary,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildStatCard(
                context,
                label: 'PACE',
                value: _formatPace(),
                icon: Icons.route_rounded,
                iconColor: AppColors.accent3,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildRunButton(BuildContext context) {
    if (runningSession.isPaused) {
      return Row(
        children: [
          Expanded(
            child: AppButton.primary(
              onPressed: _retomarCorrida,
              icon: Icons.play_arrow_rounded,
              label: "Retomar",
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton.danger(
              onPressed: _pararCorrida,
              icon: Icons.stop_rounded,
              label: "Finalizar",
            ),
          ),
        ],
      );
    }

    if (_corridaIniciada) {
      return Row(
        children: [
          Expanded(
            child: AppButton.secondary(
              onPressed: _pausarCorrida,
              icon: Icons.pause_rounded,
              label: "Pausar",
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton.danger(
              onPressed: _pararCorrida,
              icon: Icons.stop_rounded,
              label: "Finalizar",
            ),
          ),
        ],
      );
    }

    return AppButton.primary(
      onPressed: _iniciarCorrida,
      icon: Icons.play_arrow_rounded,
      label: "Iniciar Corrida",
    );
  }

  Widget _buildHistoricoButton(BuildContext context) {
    return AppButton.secondary(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoricoCorridasPage()),
        );
      },
      icon: Icons.history_rounded,
      label: 'Ver Historico',
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(24),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFFF1744),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            "AO VIVO",
            style: TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
