import 'package:flutter/material.dart';

import '../../../settings/settings.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/corrida_model.dart';
import '../../../../screens/corridas/corrida_detalhe_page.dart';
import '../../../../screens/widgets/activities/activities_navigation_header.dart';
import '../../../../screens/widgets/activities/activity_page_entrance.dart';
import '../../data/activities_timeline_repository.dart';
import '../../domain/activity_query.dart';

class ActivitiesCalendarPage extends StatefulWidget {
  const ActivitiesCalendarPage({
    super.key,
    this.repository = const ActivitiesTimelineRepository(),
    this.initialMonth,
  });

  final ActivitiesTimelineRepository repository;
  final DateTime? initialMonth;

  @override
  State<ActivitiesCalendarPage> createState() => _ActivitiesCalendarPageState();
}

class _ActivitiesCalendarPageState extends State<ActivitiesCalendarPage> {
  late DateTime _month;
  late DateTime _selectedDate;
  UnifiedActivityCalendarMonth? _calendar;
  var _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMonth ?? DateTime.now();
    _month = DateTime(initial.year, initial.month);
    _selectedDate = DateTime(initial.year, initial.month, initial.day);
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final calendar = await widget.repository.loadCalendarMonth(_month);
      if (!mounted) return;
      setState(() => _calendar = calendar);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDate = DateTime(_month.year, _month.month, 1);
    });
    _loadMonth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ActivityPageEntrance(
          child: ListView(
            key: const PageStorageKey('activities-calendar-scroll'),
            padding: const EdgeInsets.fromLTRB(
              FitSpacing.s20,
              FitSpacing.s12,
              FitSpacing.s20,
              FitSpacing.s32,
            ),
            children: [
              const ActivitiesNavigationHeader(
                title: 'Calendario de atividades',
                subtitle: 'Corridas e resumo diario de passos.',
              ),
              const SizedBox(height: FitSpacing.s20),
              if (_loading)
                const FitLoadingCard()
              else if (_error != null)
                FitErrorState(
                  title: 'Calendario indisponivel',
                  error: 'Nao foi possivel consultar os dados locais.',
                  onRetry: _loadMonth,
                )
              else if (_calendar != null) ...[
                _CalendarCard(
                  calendar: _calendar!,
                  selectedDate: _selectedDate,
                  onPrevious: () => _changeMonth(-1),
                  onNext: () => _changeMonth(1),
                  onSelect: (date) => setState(() => _selectedDate = date),
                ),
                const SizedBox(height: FitSpacing.s20),
                _SelectedDayDetails(
                  day: _calendar!.dayFor(_selectedDate),
                  selectedDate: _selectedDate,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.calendar,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onSelect,
  });

  final UnifiedActivityCalendarMonth calendar;
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final month = calendar.month;
    final offset = month.weekday - 1;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = ((offset + days + 6) ~/ 7) * 7;
    return FitCard(
      title: 'Calendario',
      subtitle: 'Corrida e meta de passos usam indicadores distintos.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _monthLabel(month),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FitIconButton(
                icon: FitIcons.back,
                tooltip: 'Mes anterior',
                onPressed: onPrevious,
              ),
              FitIconButton(
                icon: FitIcons.forward,
                tooltip: 'Proximo mes',
                onPressed: onNext,
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s12),
          const _WeekDays(),
          const SizedBox(height: FitSpacing.s8),
          GridView.builder(
            shrinkWrap: true,
            primary: false,
            itemCount: cells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: FitSpacing.s4,
              crossAxisSpacing: FitSpacing.s4,
              mainAxisExtent: FitLayout.minimumTouchTarget,
            ),
            itemBuilder: (context, index) {
              final day = index - offset + 1;
              if (day <= 0 || day > days) return const SizedBox.shrink();
              final date = DateTime(month.year, month.month, day);
              return _UnifiedCalendarCell(
                day: calendar.dayFor(date),
                selected: _sameDay(date, selectedDate),
                future: date.isAfter(_today()),
                onTap: () => onSelect(date),
              );
            },
          ),
          const SizedBox(height: FitSpacing.s12),
          const _CalendarLegend(),
        ],
      ),
    );
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String _monthLabel(DateTime value) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Marco',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${months[value.month - 1]} ${value.year}';
  }
}

class _WeekDays extends StatelessWidget {
  const _WeekDays();

  @override
  Widget build(BuildContext context) {
    const labels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
      ],
    );
  }
}

class _UnifiedCalendarCell extends StatelessWidget {
  const _UnifiedCalendarCell({
    required this.day,
    required this.selected,
    required this.future,
    required this.onTap,
  });

  final UnifiedActivityCalendarDay? day;
  final bool selected;
  final bool future;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = day?.date;
    final hasRun = day?.hasRun ?? false;
    final goalReached = day?.stepsGoalReached ?? false;
    final hasSteps = day?.hasStepsData ?? false;
    final label = date == null
        ? 'Dia indisponivel'
        : '${date.day}. ${future ? 'Dia futuro' : ''}${hasRun ? ' Corrida registrada.' : ''}${hasSteps ? ' ${day!.steps!.steps} passos.' : ' Passos indisponiveis.'}${goalReached ? ' Meta atingida.' : ''}';
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: InkWell(
        borderRadius: FitRadius.mediumBorder,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: FitRadius.mediumBorder,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(date?.day.toString() ?? ''),
              if (hasRun)
                const Positioned(
                  left: FitSpacing.s2,
                  bottom: FitSpacing.s2,
                  child: Icon(FitIcons.running, size: FitLayout.iconSizeBadge),
                ),
              if (goalReached)
                Positioned(
                  right: FitSpacing.s2,
                  bottom: FitSpacing.s2,
                  child: Icon(
                    FitIcons.check,
                    color: Theme.of(context).colorScheme.primary,
                    size: FitLayout.iconSizeBadge,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Legenda: icone de corrida indica sessao. Marca de verificacao indica meta de passos atingida.',
      child: Wrap(
        spacing: FitSpacing.s12,
        runSpacing: FitSpacing.s8,
        children: const [
          _LegendItem(icon: FitIcons.running, label: 'Corrida'),
          _LegendItem(icon: FitIcons.check, label: 'Meta de passos'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: FitLayout.iconSizeSmall),
      const SizedBox(width: FitSpacing.s4),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

class _SelectedDayDetails extends StatelessWidget {
  const _SelectedDayDetails({required this.day, required this.selectedDate});

  final UnifiedActivityCalendarDay? day;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final runs = day?.runs ?? const [];
    final steps = day?.steps;
    return FitSection(
      title:
          'Dia ${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}',
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          FitCard(
            title: 'Passos',
            subtitle: steps == null
                ? 'Dados indisponiveis neste dia.'
                : '${steps.steps} de ${steps.goal} passos - ${steps.sourceLabel}',
            leading: const Icon(FitIcons.steps),
            trailing: steps == null
                ? const FitBadge(label: 'Indisponivel')
                : FitBadge(
                    label: steps.goalCompleted ? 'Meta atingida' : 'Registrado',
                    tone: steps.goalCompleted
                        ? FitBadgeTone.success
                        : FitBadgeTone.neutral,
                  ),
            child: const SizedBox(),
          ),
          const SizedBox(height: FitSpacing.s12),
          if (runs.isEmpty)
            const FitCard(
              title: 'Corridas',
              subtitle: 'Nenhuma corrida registrada neste dia.',
              leading: Icon(FitIcons.running),
              child: SizedBox(),
            )
          else
            for (final run in runs) ...[
              _CalendarRunRow(run: run),
              const SizedBox(height: FitSpacing.s12),
            ],
        ],
      ),
    );
  }
}

class _CalendarRunRow extends StatelessWidget {
  const _CalendarRunRow({required this.run});

  final CorridaModel run;

  @override
  Widget build(BuildContext context) {
    final units = WorkoutSettingsRuntime.units;
    return FitCard(
      title: UnitConversion.formatDistanceKm(run.distancia, units),
      subtitle:
          '${run.segundos ~/ 60} min - ${UnitConversion.formatPaceMinutesPerKm(run.pace, units)}',
      leading: const Icon(FitIcons.running),
      trailing: const Icon(FitIcons.forward),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CorridaDetalhePorIdPage(runId: run.id),
        ),
      ),
      child: const SizedBox(),
    );
  }
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
