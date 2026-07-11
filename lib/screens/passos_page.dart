import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/steps_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';

class PassosPage extends StatefulWidget {
  final int passos;

  const PassosPage({super.key, required this.passos});

  @override
  State<PassosPage> createState() => _PassosPageState();
}

class _PassosPageState extends State<PassosPage> {
  final stepsService = StepsService.instance;

  @override
  void initState() {
    super.initState();
    stepsService.addListener(_onStepsChanged);
    unawaited(stepsService.initialize());
  }

  @override
  void dispose() {
    stepsService.removeListener(_onStepsChanged);
    super.dispose();
  }

  void _onStepsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  int get _passos => stepsService.initialized
      ? stepsService.stepsToday
      : widget.passos.clamp(0, 1000000);

  int get _meta => stepsService.dailyGoal;

  double get _progresso => stepsService.initialized
      ? stepsService.progressToday
      : (_passos / _meta).clamp(0.0, 1.0);

  String get _statusMeta {
    if (_passos >= _meta) return 'Meta atingida!';
    return '${(_meta - _passos).clamp(0, _meta)} passos para a meta';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _buildProgressRing(context),
                const SizedBox(height: 24),
                _buildStatsWrap(context),
                const SizedBox(height: 24),
                _buildMetaCard(context),
              ]),
            ),
          ),
        ],
      ),
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
        eyebrow: stepsService.usingHealthConnect ? 'Health Connect' : 'Hoje',
        title: 'Passos',
        subtitle: _statusMeta,
        icon: Icons.directions_walk_rounded,
        gradient: AppColors.gradientSteps,
      ),
    );
  }

  Widget _buildProgressRing(BuildContext context) {
    return AppGradientCard(
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _RingPainter(progress: _progresso),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_passos',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'passos',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _statusMeta,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _passos >= _meta
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          AppButton.primary(
            label: 'Sincronizar agora',
            icon: Icons.sync_rounded,
            loading: stepsService.syncing,
            onPressed: stepsService.syncing
                ? null
                : () =>
                      unawaited(stepsService.syncNow(requestPermission: true)),
          ),
          const SizedBox(height: 8),
          Text(
            stepsService.statusMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsWrap(BuildContext context) {
    final best = stepsService.bestDayThisWeek;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statChip(
          label: 'Calorias',
          value: '${stepsService.estimatedCalories.toStringAsFixed(0)} kcal',
          icon: Icons.local_fire_department_outlined,
          color: AppColors.accent2,
        ),
        _statChip(
          label: 'Distancia',
          value: '${stepsService.estimatedDistanceKm.toStringAsFixed(2)} km',
          icon: Icons.route_outlined,
          color: AppColors.accent1,
        ),
        _statChip(
          label: 'Media semanal',
          value: '${stepsService.weeklyAverage}',
          icon: Icons.query_stats_rounded,
          color: AppColors.primary,
        ),
        _statChip(
          label: 'Melhor semana',
          value: best == null ? '--' : '${best.steps}',
          icon: Icons.emoji_events_outlined,
          color: AppColors.rankOuro,
        ),
      ],
    );
  }

  Widget _statChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: 155,
      child: AppStatChip(
        label: label,
        value: value,
        icon: icon,
        iconColor: color,
      ),
    );
  }

  Widget _buildMetaCard(BuildContext context) {
    return AppGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent1.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  color: AppColors.accent1,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Meta diaria',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Text(
                '${(_progresso * 100).toStringAsFixed(0)}%',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Container(
              height: 10,
              color: const Color(0xFF2A2A2A),
              child: FractionallySizedBox(
                widthFactor: _progresso,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.gradientSteps,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_passos passos',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '$_meta passos',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const strokeWidth = 14.0;

    final trackPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.accent1, Color(0xFF7C4DFF)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
