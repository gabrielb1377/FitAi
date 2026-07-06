import 'package:flutter/material.dart';

import '../../../services/evolucao_dashboard_service.dart';
import '../../../theme/app_theme.dart';

class EvolucaoHero extends StatelessWidget {
  final EvolucaoDashboardData dados;

  const EvolucaoHero({super.key, required this.dados});

  @override
  Widget build(BuildContext context) {
    return AppGradientCard(
      gradient: AppColors.gradientPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EVOLUÇÃO',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seu painel de performance',
            style: TextStyle(
              color: Colors.black,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${dados.historico.length} treinos finalizados • ${_formatarPeso(dados.semanaAtual.volume)} nesta semana',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class EvolucaoSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const EvolucaoSectionTitle({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 21),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class SemanaResumoCard extends StatelessWidget {
  final SemanaEvolucaoResumo semana;

  const SemanaResumoCard({super.key, required this.semana});

  @override
  Widget build(BuildContext context) {
    return _AnimatedDashboardCard(
      child: AppGradientCard(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricBox(
              icon: Icons.check_circle_rounded,
              label: 'Treinos',
              value: '${semana.treinos}',
            ),
            _MetricBox(
              icon: Icons.timer_rounded,
              label: 'Tempo',
              value: _formatarDuracao(semana.tempoSegundos),
            ),
            _MetricBox(
              icon: Icons.monitor_weight_rounded,
              label: 'Volume',
              value: _formatarPeso(semana.volume),
            ),
            _MetricBox(
              icon: Icons.fitness_center_rounded,
              label: 'Exercícios',
              value: '${semana.exercicios}',
            ),
          ],
        ),
      ),
    );
  }
}

class CargaEvolucaoCard extends StatelessWidget {
  final CargaEvolucaoResumo carga;

  const CargaEvolucaoCard({super.key, required this.carga});

  @override
  Widget build(BuildContext context) {
    if (!carga.possuiDados) {
      return const _EmptyCard(
        icon: Icons.show_chart_rounded,
        title: 'Sem cargas registradas',
        message: 'Registre séries com peso para acompanhar sua evolução.',
      );
    }

    final diffColor = carga.diferencaPercentual > 0
        ? AppColors.primary
        : carga.diferencaPercentual < 0
        ? const Color(0xFFFF6B6B)
        : const Color(0xFFFFC857);

    return _AnimatedDashboardCard(
      child: AppGradientCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              carga.exercicio,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            _InfoLine('Última carga', _formatarPeso(carga.ultimaCarga)),
            _InfoLine('Melhor carga', _formatarPeso(carga.melhorCarga)),
            _InfoLine(
              'Diferença',
              '${carga.diferencaPercentual >= 0 ? '+' : ''}${carga.diferencaPercentual.toStringAsFixed(0)}%',
              valueColor: diffColor,
            ),
            _InfoLine(
              'Última atualização',
              _formatarData(carga.ultimaAtualizacao),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class RecordesPessoaisCard extends StatelessWidget {
  final List<RecordePessoalResumo> recordes;

  const RecordesPessoaisCard({super.key, required this.recordes});

  @override
  Widget build(BuildContext context) {
    return _AnimatedDashboardCard(
      child: AppGradientCard(
        child: Column(
          children: [
            for (var index = 0; index < recordes.length; index++)
              _RecordeTile(
                recorde: recordes[index],
                isLast: index == recordes.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class FrequenciaCard extends StatelessWidget {
  final FrequenciaResumo frequencia;

  const FrequenciaCard({super.key, required this.frequencia});

  @override
  Widget build(BuildContext context) {
    return _AnimatedDashboardCard(
      child: AppGradientCard(
        child: Column(
          children: [
            _InfoLine('Treinos por semana', '${frequencia.treinosSemana}'),
            _InfoLine('Dias consecutivos', '${frequencia.diasConsecutivos}'),
            _InfoLine(
              'Maior sequência',
              '${frequencia.maiorSequencia} dias',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class MusculosTreinadosCard extends StatelessWidget {
  final List<MusculoTreinadoResumo> musculos;

  const MusculosTreinadosCard({super.key, required this.musculos});

  @override
  Widget build(BuildContext context) {
    return _AnimatedDashboardCard(
      child: AppGradientCard(
        child: Column(
          children: [
            for (var index = 0; index < musculos.length; index++)
              _MuscleBar(
                musculo: musculos[index],
                isLast: index == musculos.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class CoachFitiaCard extends StatelessWidget {
  final List<CoachInsightResumo> insights;

  const CoachFitiaCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    return _AnimatedDashboardCard(
      child: AppGradientCard(
        child: Column(
          children: [
            for (var index = 0; index < insights.length; index++)
              _InsightTile(
                insight: insights[index],
                isLast: index == insights.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class EvolucaoEmptyState extends StatelessWidget {
  const EvolucaoEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: AppEmptyState(
        icon: Icons.auto_graph_rounded,
        title: 'Complete seu primeiro treino para ver sua evolução.',
        message: 'Quando você finalizar treinos, seus números aparecem aqui.',
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 142,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withAlpha(14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _InfoLine(
    this.label,
    this.value, {
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordeTile extends StatelessWidget {
  final RecordePessoalResumo recorde;
  final bool isLast;

  const _RecordeTile({required this.recorde, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final hasRecord = recorde.carga > 0;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withAlpha(28),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFD700),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recorde.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasRecord ? recorde.exercicio ?? 'Recorde' : 'Sem registro',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            hasRecord ? _formatarPeso(recorde.carga) : '--',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleBar extends StatelessWidget {
  final MusculoTreinadoResumo musculo;
  final bool isLast;

  const _MuscleBar({required this.musculo, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  musculo.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${musculo.total}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: musculo.percentual.clamp(0.0, 1.0).toDouble(),
              color: AppColors.primary,
              backgroundColor: Colors.white.withAlpha(18),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final CoachInsightResumo insight;
  final bool isLast;

  const _InsightTile({required this.insight, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = switch (insight.tipo) {
      CoachInsightTipo.positivo => AppColors.primary,
      CoachInsightTipo.alerta => const Color(0xFFFFC857),
      CoachInsightTipo.neutro => AppColors.accent1,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.descricao,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimatedDashboardCard(
      child: AppGradientCard(
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedDashboardCard extends StatelessWidget {
  final Widget child;

  const _AnimatedDashboardCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.97, end: 1),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: child,
    );
  }
}

String _formatarPeso(double peso) {
  if (peso <= 0) return '0 kg';
  if (peso >= 1000) return '${_formatarNumero(peso / 1000)} t';
  return '${_formatarNumero(peso)} kg';
}

String _formatarNumero(double valor) {
  if (valor == valor.roundToDouble()) return valor.round().toString();
  return valor.toStringAsFixed(1).replaceAll('.', ',');
}

String _formatarDuracao(int segundos) {
  if (segundos <= 0) return '0 min';
  final horas = segundos ~/ 3600;
  final minutos = (segundos % 3600) ~/ 60;
  if (horas <= 0) return '${minutos}min';
  if (minutos <= 0) return '${horas}h';
  return '${horas}h ${minutos}min';
}

String _formatarData(DateTime data) {
  if (data.millisecondsSinceEpoch == 0) return '--';
  final local = data.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}
