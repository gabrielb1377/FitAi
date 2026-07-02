import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';

class PassosPage extends StatelessWidget {
  final int passos;

  const PassosPage({super.key, required this.passos});

  static const int metaPassos = 10000;

  double get progresso => (passos / metaPassos).clamp(0.0, 1.0);

  double get caloriasEstimadas => passos * 0.04;

  double get distanciaEstimada => passos * 0.000762;

  String get statusMeta {
    if (passos >= metaPassos) return 'ðŸŽ‰ Meta atingida!';
    final restantes = metaPassos - passos;
    return '$restantes passos para a meta';
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
                // Anel de progresso
                _buildProgressRing(context),
                const SizedBox(height: 24),

                // Stats
                _buildStatsRow(context),
                const SizedBox(height: 24),

                // Meta
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
        eyebrow: "Hoje",
        title: "Passos",
        subtitle: statusMeta,
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
              painter: _RingPainter(progress: progresso),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$passos',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -1,
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
            statusMeta,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: passos >= metaPassos
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppStatChip(
            label: 'Calorias',
            value: '${caloriasEstimadas.toStringAsFixed(0)} kcal',
            icon: Icons.local_fire_department_outlined,
            iconColor: AppColors.accent2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppStatChip(
            label: 'DistÃ¢ncia',
            value: '${distanciaEstimada.toStringAsFixed(2)} km',
            icon: Icons.route_outlined,
            iconColor: AppColors.accent1,
          ),
        ),
      ],
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
                'Meta DiÃ¡ria',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Text(
                '${(progresso * 100).toStringAsFixed(0)}%',
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
                widthFactor: progresso,
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
                '$passos passos',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '$metaPassos passos',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Painter do anel de progresso â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const strokeWidth = 14.0;

    // Trilha
    final trackPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progresso
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
