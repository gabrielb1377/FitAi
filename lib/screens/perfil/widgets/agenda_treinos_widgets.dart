import 'package:flutter/material.dart';

import '../../../services/agenda_treinos_service.dart';
import '../../../theme/app_theme.dart';

class AgendaResumoCard extends StatelessWidget {
  final AgendaResumoTreinos resumo;

  const AgendaResumoCard({super.key, required this.resumo});

  @override
  Widget build(BuildContext context) {
    return AppGradientCard(
      gradient: AppColors.gradientPrimary,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _ResumoPill(
            icon: Icons.local_fire_department_rounded,
            label: 'Sequência',
            value: '${resumo.sequenciaAtual} dias',
          ),
          _ResumoPill(
            icon: Icons.workspace_premium_rounded,
            label: 'Maior',
            value: '${resumo.maiorSequencia} dias',
          ),
          _ResumoPill(
            icon: Icons.fitness_center_rounded,
            label: 'Treinos no mês',
            value: '${resumo.treinosMes}',
          ),
          _ResumoPill(
            icon: Icons.event_busy_rounded,
            label: 'Dias perdidos',
            value: '${resumo.diasPerdidos}',
          ),
        ],
      ),
    );
  }
}

class AgendaCoachCard extends StatelessWidget {
  final AgendaCoachSugestao sugestao;
  final VoidCallback onMover;

  const AgendaCoachCard({
    super.key,
    required this.sugestao,
    required this.onMover,
  });

  @override
  Widget build(BuildContext context) {
    return AppGradientCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(28),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coach FitIA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  sugestao.mensagem,
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onMover,
                  icon: const Icon(Icons.event_repeat_rounded, size: 18),
                  label: const Text('Mover para amanhã'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AgendaCalendarCard extends StatelessWidget {
  final DateTime mes;
  final List<AgendaDiaTreino> dias;
  final ValueChanged<AgendaDiaTreino> onDiaTap;

  const AgendaCalendarCard({
    super.key,
    required this.mes,
    required this.dias,
    required this.onDiaTap,
  });

  @override
  Widget build(BuildContext context) {
    final primeiroDia = DateTime(mes.year, mes.month);
    final offset = primeiroDia.weekday - DateTime.monday;
    final cells = <Widget>[
      for (final label in const ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'])
        _WeekLabel(label),
      for (var i = 0; i < offset; i++) const SizedBox.shrink(),
      for (final dia in dias)
        AgendaDayCell(dia: dia, onTap: () => onDiaTap(dia)),
    ];

    return AppGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _nomeMes(mes),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.82,
            children: cells,
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              AgendaLegend(label: 'Programado', color: AppColors.accent1),
              AgendaLegend(label: 'Concluído', color: AppColors.primary),
              AgendaLegend(label: 'Pendente', color: Color(0xFFFFC857)),
              AgendaLegend(label: 'Corrida', color: AppColors.accent3),
              AgendaLegend(label: 'Descanso', color: Colors.white38),
            ],
          ),
        ],
      ),
    );
  }
}

class AgendaDayCell extends StatelessWidget {
  final AgendaDiaTreino dia;
  final VoidCallback onTap;

  const AgendaDayCell({super.key, required this.dia, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hoje = _mesmoDia(dia.data, DateTime.now());
    final color = _statusColor(dia.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: hoje ? color.withAlpha(28) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hoje ? color : Colors.white.withAlpha(12),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${dia.data.day}',
                style: TextStyle(
                  color: hoje ? color : Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Icon(_statusIcon(dia.status), color: color, size: 17),
              if (dia.temCorrida && dia.status != AgendaTreinoStatus.corrida)
                const Icon(
                  Icons.directions_run_rounded,
                  color: AppColors.accent3,
                  size: 13,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AgendaLegend extends StatelessWidget {
  final String label;
  final Color color;

  const AgendaLegend({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class AgendaDayInfoSheet extends StatelessWidget {
  final AgendaDiaTreino dia;
  final VoidCallback onDescanso;
  final VoidCallback onReagendar;
  final VoidCallback onMoverAmanha;
  final VoidCallback onPular;

  const AgendaDayInfoSheet({
    super.key,
    required this.dia,
    required this.onDescanso,
    required this.onReagendar,
    required this.onMoverAmanha,
    required this.onPular,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1218),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withAlpha(18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(70),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '${dia.data.day.toString().padLeft(2, '0')}/${dia.data.month.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              dia.grupoMuscular,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              'Plano',
              dia.planoNome.isEmpty ? 'Sem plano' : dia.planoNome,
            ),
            _InfoRow(
              'Dia do treino',
              dia.diaCodigo.isEmpty ? '-' : dia.diaCodigo,
            ),
            _InfoRow('Grupo muscular', dia.grupoMuscular),
            _InfoRow('Exercícios', '${dia.quantidadeExercicios}'),
            _InfoRow('Tempo previsto', '${dia.tempoPrevisto} min'),
            _InfoRow('Status', dia.statusLabel),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SheetAction(
                  icon: Icons.hotel_rounded,
                  label: 'Marcar descanso',
                  onTap: onDescanso,
                ),
                _SheetAction(
                  icon: Icons.event_repeat_rounded,
                  label: 'Reagendar',
                  onTap: onReagendar,
                ),
                _SheetAction(
                  icon: Icons.arrow_forward_rounded,
                  label: 'Mover para amanhã',
                  onTap: onMoverAmanha,
                ),
                _SheetAction(
                  icon: Icons.skip_next_rounded,
                  label: 'Pular treino',
                  danger: true,
                  onTap: onPular,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ResumoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(24),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekLabel extends StatelessWidget {
  final String label;

  const _WeekLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFFF6B6B) : AppColors.primary;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withAlpha(110)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

Color _statusColor(AgendaTreinoStatus status) {
  return switch (status) {
    AgendaTreinoStatus.programado => AppColors.accent1,
    AgendaTreinoStatus.concluido => AppColors.primary,
    AgendaTreinoStatus.pendente => const Color(0xFFFFC857),
    AgendaTreinoStatus.corrida => AppColors.accent3,
    AgendaTreinoStatus.descanso => Colors.white38,
    AgendaTreinoStatus.pulado => const Color(0xFFFF6B6B),
    AgendaTreinoStatus.reagendado => AppColors.accent2,
  };
}

IconData _statusIcon(AgendaTreinoStatus status) {
  return switch (status) {
    AgendaTreinoStatus.programado => Icons.circle_rounded,
    AgendaTreinoStatus.concluido => Icons.check_circle_rounded,
    AgendaTreinoStatus.pendente => Icons.pending_rounded,
    AgendaTreinoStatus.corrida => Icons.directions_run_rounded,
    AgendaTreinoStatus.descanso => Icons.hotel_rounded,
    AgendaTreinoStatus.pulado => Icons.skip_next_rounded,
    AgendaTreinoStatus.reagendado => Icons.event_repeat_rounded,
  };
}

String _nomeMes(DateTime mes) {
  const nomes = [
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

  return '${nomes[mes.month - 1]} ${mes.year}';
}

bool _mesmoDia(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
