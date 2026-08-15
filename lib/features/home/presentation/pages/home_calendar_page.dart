import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../services/agenda_treinos_service.dart';
import '../widgets/home_detail_scaffold.dart';
import '../widgets/home_official_components.dart';

class HomeCalendarPage extends StatefulWidget {
  const HomeCalendarPage({super.key, this.loader, this.initialDate});

  final Future<AgendaTreinosMes> Function(DateTime month)? loader;
  final DateTime? initialDate;

  @override
  State<HomeCalendarPage> createState() => _HomeCalendarPageState();
}

class _HomeCalendarPageState extends State<HomeCalendarPage> {
  late DateTime _month;
  late DateTime _selectedDate;
  late Future<AgendaTreinosMes> _future;

  @override
  void initState() {
    super.initState();
    final now = _today;
    _month = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _future = _loadMonth(_month);
  }

  @override
  Widget build(BuildContext context) {
    return HomeDetailScaffold(
      title: 'Calendário',
      subtitle: '',
      actions: [
        FitIconButton(
          icon: FitIcons.calendar,
          tooltip: 'Voltar para o mês atual',
          onPressed: _goToToday,
        ),
      ],
      child: FutureBuilder<AgendaTreinosMes>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const HomePageBody(
              children: [
                FitSkeleton(height: 320),
                SizedBox(height: FitSpacing.s16),
                FitSkeleton(height: 120),
              ],
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return FitErrorState(
              error: 'Não foi possível carregar o calendário.',
              onRetry: _reload,
            );
          }
          return _content(snapshot.data!);
        },
      ),
    );
  }

  Widget _content(AgendaTreinosMes agenda) {
    final selected = agenda.dias.where((day) {
      return day.data.year == _selectedDate.year &&
          day.data.month == _selectedDate.month &&
          day.data.day == _selectedDate.day;
    }).firstOrNull;
    return HomePageBody(
      onRefresh: () async => _reload(),
      children: [
        _MonthHeader(
          month: _month,
          onPrevious: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
        ),
        const SizedBox(height: FitSpacing.s16),
        _CalendarGrid(
          agenda: agenda,
          selectedDate: _selectedDate,
          onSelected: (date) => setState(() => _selectedDate = date),
        ),
        const HomeSectionGap(),
        FitSectionHeader(
          title: _isToday(_selectedDate)
              ? 'Hoje · ${_shortDate(_selectedDate)}'
              : _shortDate(_selectedDate),
        ),
        const SizedBox(height: FitSpacing.s12),
        if (selected == null || (!selected.temTreino && !selected.temCorrida))
          const HomeListAction(
            title: 'Dia de recuperação',
            subtitle: 'Nenhuma atividade programada.',
            icon: Icons.self_improvement_rounded,
            color: FitColors.ai,
          )
        else ...[
          if (selected.temTreino)
            HomeListAction(
              title: selected.grupoMuscular,
              subtitle:
                  '${selected.quantidadeExercicios} exercícios · ${selected.tempoPrevisto} min',
              value: selected.statusLabel,
              icon: FitIcons.workout,
            ),
          if (selected.temCorrida) ...[
            const SizedBox(height: FitSpacing.s8),
            const HomeListAction(
              title: 'Corrida',
              subtitle: 'Atividade registrada neste dia.',
              icon: FitIcons.running,
              color: FitColors.running,
            ),
          ],
        ],
      ],
    );
  }

  void _changeMonth(int offset) {
    final month = DateTime(_month.year, _month.month + offset);
    setState(() {
      _month = month;
      _selectedDate = DateTime(month.year, month.month);
      _future = _loadMonth(month);
    });
  }

  void _goToToday() {
    final now = _today;
    setState(() {
      _month = DateTime(now.year, now.month);
      _selectedDate = DateTime(now.year, now.month, now.day);
      _future = _loadMonth(_month);
    });
  }

  void _reload() => setState(() => _future = _loadMonth(_month));

  Future<AgendaTreinosMes> _loadMonth(DateTime month) {
    return (widget.loader ?? const AgendaTreinosService().carregarMes)(month);
  }

  bool _isToday(DateTime value) {
    final now = _today;
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  DateTime get _today => widget.initialDate ?? DateTime.now();

  String _shortDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    const names = [
      'Janeiro',
      'Fevereiro',
      'Março',
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
    return Row(
      children: [
        FitIconButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Mês anterior',
          onPressed: onPrevious,
        ),
        Expanded(
          child: Text(
            '${names[month.month - 1]} ${month.year}',
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge,
          ),
        ),
        FitIconButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Próximo mês',
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.agenda,
    required this.selectedDate,
    required this.onSelected,
  });

  final AgendaTreinosMes agenda;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    const weekdays = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    final offset = agenda.mes.weekday - 1;
    final cells = offset + agenda.dias.length;
    return Column(
      children: [
        Row(
          children: [
            for (final day in weekdays)
              Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: context.textTheme.labelSmall,
                ),
              ),
          ],
        ),
        const SizedBox(height: FitSpacing.s8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: FitSpacing.s4,
            crossAxisSpacing: FitSpacing.s4,
          ),
          itemBuilder: (context, index) {
            if (index < offset) return const SizedBox.shrink();
            final day = agenda.dias[index - offset];
            final selected =
                day.data.day == selectedDate.day &&
                day.data.month == selectedDate.month &&
                day.data.year == selectedDate.year;
            final active = day.temTreino || day.temCorrida;
            return Semantics(
              button: true,
              selected: selected,
              label: '${day.data.day}, ${day.statusLabel}',
              child: InkWell(
                onTap: () => onSelected(day.data),
                borderRadius: FitRadius.smallBorder,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: FitRadius.smallBorder,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '${day.data.day}',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: selected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (active)
                        const Positioned(
                          bottom: FitSpacing.s4,
                          child: Icon(
                            Icons.circle,
                            size: FitSpacing.s4,
                            color: FitColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
