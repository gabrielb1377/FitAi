import 'package:flutter/material.dart';

import '../../models/treino_model.dart';
import 'controllers/plan_day_data.dart';
import 'controllers/plan_progress_snapshot.dart';
import 'official/official_plan_options_page.dart';
import 'official/official_plan_ui.dart';
import 'workout_day_page.dart';

class PlanWeeksPage extends StatefulWidget {
  const PlanWeeksPage({super.key, required this.plan, required this.progress});

  final TreinoModel plan;
  final PlanProgressSnapshot progress;

  @override
  State<PlanWeeksPage> createState() => _PlanWeeksPageState();
}

class _PlanWeeksPageState extends State<PlanWeeksPage> {
  var _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final days = buildPlanDays(widget.plan);
    return Scaffold(
      backgroundColor: OfficialPlanColors.background,
      bottomNavigationBar: _tabIndex == 0 && days.isNotEmpty
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: OfficialPlanPrimaryButton(
                label: 'Iniciar ${days.first.label}',
                onPressed: () => _openDay(days.first),
              ),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: OfficialPlanViewport(
          child: Column(
            children: [
              OfficialPlanHeader(
                title: widget.plan.nome,
                onBack: () => Navigator.maybePop(context),
                trailing: OfficialPlanIconButton(
                  icon: Icons.more_vert_rounded,
                  tooltip: 'Opções do plano',
                  onPressed: _openOptions,
                ),
              ),
              OfficialPlanTabs(
                labels: const ['Treinos', 'Resumo'],
                selectedIndex: _tabIndex,
                onSelected: (index) => setState(() => _tabIndex = index),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _tabIndex == 0 ? _workouts(days) : _summary(days),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _workouts(List<PlanDayData> days) {
    if (days.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum treino adicionado.',
          style: TextStyle(color: OfficialPlanColors.textMuted),
        ),
      );
    }
    final completed = widget.progress.weeklyCompletedWorkouts;
    return ListView.separated(
      key: const ValueKey('official-plan-workouts'),
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
      itemCount: days.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final day = days[index];
        final done = index < completed;
        return OfficialPlanSurface(
          onTap: () => _openDay(day),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 64,
                decoration: BoxDecoration(
                  color: OfficialPlanColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.accessibility_new_rounded,
                  size: 42,
                  color: OfficialPlanColors.textMuted,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: OfficialPlanColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      day.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: OfficialPlanColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.workout.exercicios.length} exercícios',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                done ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: done
                    ? OfficialPlanColors.green
                    : OfficialPlanColors.textMuted,
                size: 24,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summary(List<PlanDayData> days) {
    final groups = _muscleGroups();
    final durationWeeks = widget.progress.weeks.length.clamp(6, 8);
    return ListView(
      key: const ValueKey('official-plan-summary'),
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 20),
      children: [
        Text(
          'Visão geral',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: OfficialPlanColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _summaryStat('${days.length}', 'Treinos'),
            const SizedBox(width: 8),
            _summaryStat('${widget.plan.exercicios.length}', 'Exercícios'),
            const SizedBox(width: 8),
            _summaryStat('6–$durationWeeks', 'Semanas'),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Músculos trabalhados',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: OfficialPlanColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(
              child: SizedBox(
                height: 142,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(
                      Icons.accessibility_new_rounded,
                      size: 90,
                      color: OfficialPlanColors.textMuted,
                    ),
                    RotatedBox(
                      quarterTurns: 2,
                      child: Icon(
                        Icons.accessibility_new_rounded,
                        size: 90,
                        color: OfficialPlanColors.greenDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 118,
              child: Column(
                children: [
                  for (final group in groups.take(5))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const SizedBox.square(
                            dimension: 9,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: OfficialPlanColors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              group,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: OfficialPlanColors.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Distribuição',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: OfficialPlanColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        OfficialPlanSurface(
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 112,
                child: CustomPaint(painter: _PlanDonutPainter()),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: List.generate(groups.take(4).length, (index) {
                    final group = groups[index];
                    final percent = [30, 30, 20, 20][index];
                    final colors = const [
                      OfficialPlanColors.teal,
                      Color(0xFF0E6D75),
                      OfficialPlanColors.green,
                      Color(0xFF21956B),
                    ];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors[index],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(group)),
                          Text('$percent%'),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryStat(String value, String label) {
    return Expanded(
      child: OfficialPlanSurface(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: OfficialPlanColors.text),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  List<String> _muscleGroups() {
    final groups = <String>{
      for (final exercise in widget.plan.exercicios) ...[
        ...exercise.musculos,
        if (exercise.categoria.trim().isNotEmpty) exercise.categoria,
      ],
    }.where((item) => item.trim().isNotEmpty).toList();
    if (groups.length >= 5) return groups;
    return const ['Peito', 'Costas', 'Ombros', 'Bíceps', 'Tríceps'];
  }

  void _openDay(PlanDayData day) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDayPage(plan: widget.plan, day: day),
      ),
    );
  }

  void _openOptions() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => OfficialPlanOptionsPage(plan: widget.plan),
      ),
    );
  }
}

class _PlanDonutPainter extends CustomPainter {
  const _PlanDonutPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.shortestSide * 0.19;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    const colors = [
      OfficialPlanColors.teal,
      Color(0xFF0E6D75),
      OfficialPlanColors.green,
      Color(0xFF21956B),
    ];
    const sweeps = [0.30, 0.30, 0.20, 0.20];
    var start = -1.5708;
    for (var index = 0; index < colors.length; index++) {
      paint.color = colors[index];
      final sweep = 6.28318 * sweeps[index];
      canvas.drawArc(rect.deflate(stroke / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
