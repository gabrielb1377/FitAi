import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';
import '../../models/treino_model.dart';
import 'controllers/plan_day_data.dart';
import 'controllers/plan_progress_snapshot.dart';
import 'plan_weeks_page.dart';
import 'treino_navigation.dart';
import 'workout_day_page.dart';
import 'widgets/plans/plan_media.dart';

class TreinoDetalhesPage extends StatelessWidget {
  const TreinoDetalhesPage({super.key, required this.treino, this.progress});

  final TreinoModel treino;
  final PlanProgressSnapshot? progress;

  @override
  Widget build(BuildContext context) {
    final snapshot = progress ?? PlanProgressSnapshot.empty(treino);
    final days = buildPlanDays(treino);
    final nextIndex = snapshot.nextDayIndex.clamp(0, days.length - 1).toInt();
    final nextDay = days[nextIndex];
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _hero(context)),
          SliverToBoxAdapter(child: _body(context, snapshot, nextDay)),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
      bottomNavigationBar: _bottomAction(context, snapshot),
    );
  }

  Widget _hero(BuildContext context) {
    return SizedBox(
      height: 430,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PlanMedia(plan: treino, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Color(0x22000000),
                  FitColors.background,
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(FitSpacing.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FitIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Voltar',
                        variant: FitIconButtonVariant.subtle,
                        onPressed: () => TreinoNavigation.popOrHome(context),
                      ),
                      const Spacer(),
                      FitIconButton(
                        icon: Icons.more_horiz_rounded,
                        tooltip: 'Informacoes do plano',
                        variant: FitIconButtonVariant.subtle,
                        onPressed: () => _showPlanInfo(context),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          treino.nome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      const SizedBox(width: FitSpacing.s12),
                      const FitBadge(
                        label: 'Ativo',
                        tone: FitBadgeTone.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: FitSpacing.s8),
                  Text(
                    '$_days dias por semana - $_minutes min por treino',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: FitColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    PlanProgressSnapshot snapshot,
    PlanDayData nextDay,
  ) {
    final percent = (snapshot.weeklyProgress * 100).round();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FitCard(
                variant: FitCardVariant.outlined,
                child: Row(
                  children: [
                    Expanded(
                      child: FitMetric(
                        icon: Icons.donut_large_rounded,
                        value: '$percent%',
                        label: 'Concluido',
                        alignment: CrossAxisAlignment.center,
                      ),
                    ),
                    const SizedBox(height: 52, child: VerticalDivider()),
                    Expanded(
                      child: FitMetric(
                        icon: Icons.fitness_center_rounded,
                        value: '${snapshot.completedWorkouts}',
                        label: 'Treinos',
                        alignment: CrossAxisAlignment.center,
                      ),
                    ),
                    const SizedBox(height: 52, child: VerticalDivider()),
                    Expanded(
                      child: FitMetric(
                        icon: Icons.calendar_view_week_rounded,
                        value: '${snapshot.weeks.length - 2}',
                        label: 'Semanas',
                        alignment: CrossAxisAlignment.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FitSpacing.s24),
              Text(
                'Proximo treino',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: FitSpacing.s12),
              FitCard(
                variant: FitCardVariant.clickable,
                padding: const EdgeInsets.all(FitSpacing.s12),
                onTap: () => _openDay(context, nextDay),
                semanticLabel: 'Abrir proximo treino ${nextDay.title}',
                child: Row(
                  children: [
                    PlanMedia(plan: nextDay.workout, width: 72, height: 72),
                    const SizedBox(width: FitSpacing.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextDay.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: FitSpacing.s4),
                          Text(
                            '${nextDay.label} - $_minutes min',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: FitSpacing.s24),
              Text(
                'Visao geral do plano',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: FitSpacing.s12),
              FitCard(
                variant: FitCardVariant.outlined,
                padding: const EdgeInsets.symmetric(
                  horizontal: FitSpacing.s16,
                  vertical: FitSpacing.s8,
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.calendar_view_week_rounded,
                      label: 'Semanas acompanhadas',
                      value: '${snapshot.weeks.length - 2}',
                    ),
                    const FitDivider(),
                    _InfoRow(
                      icon: Icons.event_available_rounded,
                      label: 'Dias de treino',
                      value: '$_days dias por semana',
                    ),
                    const FitDivider(),
                    _InfoRow(
                      icon: Icons.track_changes_rounded,
                      label: 'Objetivo',
                      value: treino.objetivo,
                    ),
                    const FitDivider(),
                    _InfoRow(
                      icon: Icons.signal_cellular_alt_rounded,
                      label: 'Nivel',
                      value: treino.nivel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomAction(BuildContext context, PlanProgressSnapshot snapshot) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        FitSpacing.s20,
        FitSpacing.s8,
        FitSpacing.s20,
        FitSpacing.s16,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: FitButton(
            label: 'Ver plano completo',
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => PlanWeeksPage(plan: treino, progress: snapshot),
              ),
            ),
            expand: true,
          ),
        ),
      ),
    );
  }

  Future<void> _showPlanInfo(BuildContext context) async {
    await FitDialog.show<void>(
      context: context,
      title: treino.nome,
      message: treino.descricao.trim().isEmpty
          ? 'Plano salvo localmente no FitIA.'
          : treino.descricao,
      icon: Icons.info_outline_rounded,
    );
  }

  void _openDay(BuildContext context, PlanDayData day) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDayPage(plan: treino, day: day),
      ),
    );
  }

  int get _days => treino.planoDias.isNotEmpty
      ? treino.planoDias.length
      : treino.diasPorSemana <= 0
      ? 1
      : treino.diasPorSemana;

  int get _minutes => treino.tempoEstimado <= 0 ? 45 : treino.tempoEstimado;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Row(
        children: [
          Icon(icon, color: FitColors.primary, size: 20),
          const SizedBox(width: FitSpacing.s12),
          Expanded(child: Text(label)),
          const SizedBox(width: FitSpacing.s12),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
