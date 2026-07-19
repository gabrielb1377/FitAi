import 'package:flutter/material.dart';

import '../../models/treino_model.dart';
import 'controllers/plan_day_data.dart';
import 'controllers/plan_progress_snapshot.dart';
import 'official/official_plan_editor_page.dart';
import 'official/official_plan_options_page.dart';
import 'official/official_plan_progress_page.dart';
import 'official/official_plan_ui.dart';
import 'plan_weeks_page.dart';
import 'treino_navigation.dart';
import 'widgets/plans/plan_media.dart';
import 'workout_day_page.dart';

class TreinoDetalhesPage extends StatefulWidget {
  const TreinoDetalhesPage({super.key, required this.treino, this.progress});

  final TreinoModel treino;
  final PlanProgressSnapshot? progress;

  @override
  State<TreinoDetalhesPage> createState() => _TreinoDetalhesPageState();
}

class _TreinoDetalhesPageState extends State<TreinoDetalhesPage> {
  late TreinoModel _plan = widget.treino;

  PlanProgressSnapshot get _progress =>
      widget.progress ?? PlanProgressSnapshot.empty(_plan);

  @override
  Widget build(BuildContext context) {
    final days = buildPlanDays(_plan);
    final completed = _progress.weeklyCompletedWorkouts.clamp(0, days.length);
    final value = days.isEmpty ? 0.0 : completed / days.length;
    return Scaffold(
      backgroundColor: OfficialPlanColors.background,
      bottomNavigationBar: days.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: OfficialPlanPrimaryButton(
                label: 'Iniciar ${days[_nextIndex(days)].label}',
                onPressed: () => _openDay(days[_nextIndex(days)]),
              ),
            ),
      body: SafeArea(
        bottom: false,
        child: OfficialPlanViewport(
          child: Column(
            children: [
              _hero(),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -10),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: OfficialPlanColors.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      border: Border(
                        top: BorderSide(color: OfficialPlanColors.border),
                      ),
                    ),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                      children: [
                        _identity(value),
                        const SizedBox(height: 13),
                        _stats(days.length),
                        const SizedBox(height: 12),
                        OfficialPlanSurface(
                          child: Text(
                            _description,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: OfficialPlanColors.textMuted,
                                  height: 1.45,
                                ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _openPlanOverview,
                          child: Text(
                            'Treinos do plano',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: OfficialPlanColors.text,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _dayList(days, completed),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return SizedBox(
      height: 186,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PlanMedia(plan: _plan, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0x99000000)],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: OfficialPlanHeader(
              title: '',
              onBack: () => TreinoNavigation.popOrHome(context),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OfficialPlanIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Editar plano',
                    onPressed: _edit,
                  ),
                  OfficialPlanIconButton(
                    icon: Icons.more_vert_rounded,
                    tooltip: 'Opções do plano',
                    onPressed: _openOptions,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _identity(double value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _plan.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: OfficialPlanColors.text,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$_dayCount treinos · $_shortSplit',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 3),
              Text(
                'Criado por você',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        InkWell(
          onTap: _openProgress,
          borderRadius: BorderRadius.circular(99),
          child: OfficialPlanProgressRing(value: value, size: 58),
        ),
      ],
    );
  }

  Widget _stats(int dayCount) {
    final weeks = _progress.weeks.length.clamp(4, 8);
    return Row(
      children: [
        _stat('Duração', '4–$weeks semanas'),
        const SizedBox(width: 8),
        _stat('Nível', _plan.nivel),
        const SizedBox(width: 8),
        _stat('Objetivo', _plan.objetivo),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: OfficialPlanSurface(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: OfficialPlanColors.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayList(List<PlanDayData> days, int completed) {
    if (days.isEmpty) {
      return const OfficialPlanSurface(
        child: Text(
          'Adicione um treino para começar.',
          style: TextStyle(color: OfficialPlanColors.textMuted),
        ),
      );
    }
    return OfficialPlanSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(days.length, (index) {
          final day = days[index];
          final done = index < completed;
          return InkWell(
            onTap: _openPlanOverview,
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: index == days.length - 1
                  ? null
                  : const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: OfficialPlanColors.border),
                      ),
                    ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${day.label} - ${day.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: OfficialPlanColors.text,
                      ),
                    ),
                  ),
                  Icon(
                    done ? Icons.check_rounded : Icons.circle_outlined,
                    size: 20,
                    color: done
                        ? OfficialPlanColors.green
                        : OfficialPlanColors.textMuted,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  int _nextIndex(List<PlanDayData> days) {
    return _progress.nextDayIndex.clamp(0, days.length - 1).toInt();
  }

  int get _dayCount =>
      _plan.planoDias.isNotEmpty ? _plan.planoDias.length : _plan.diasPorSemana;

  String get _shortSplit {
    final split = _plan.divisao.trim();
    if (split.isEmpty) return 'Personalizado';
    return split.replaceAll(' / Lower', '').replaceAll('/Lower', '');
  }

  String get _description => _plan.descricao.trim().isEmpty
      ? 'Foco em desenvolver os principais grupos musculares com exercícios compostos e progressão de carga.'
      : _plan.descricao;

  void _openDay(PlanDayData day) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDayPage(plan: _plan, day: day),
      ),
    );
  }

  void _openPlanOverview() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PlanWeeksPage(plan: _plan, progress: _progress),
      ),
    );
  }

  void _openProgress() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OfficialPlanProgressPage(plan: _plan, progress: _progress),
      ),
    );
  }

  Future<void> _edit() async {
    TreinoModel? updated;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OfficialPlanEditorPage(
          initialPlan: _plan,
          onSaved: (value) => updated = value,
        ),
      ),
    );
    if (!mounted || changed != true || updated == null) return;
    setState(() => _plan = updated!);
  }

  Future<void> _openOptions() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => OfficialPlanOptionsPage(plan: _plan)),
    );
    if (!mounted || changed != true) return;
    Navigator.pop(context, true);
  }
}
