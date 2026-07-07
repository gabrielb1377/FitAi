import 'package:flutter/material.dart';

import '../../../models/exercicio_model.dart';
import '../../../services/progressao_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/exercicio_gif_viewer.dart';

class ExerciseHubTopBar extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onFavorite;

  const ExerciseHubTopBar({
    super.key,
    required this.isFavorite,
    required this.onBack,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Exercise Hub',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: isFavorite ? 'Remover dos favoritos' : 'Favoritar',
          onPressed: onFavorite,
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? AppColors.accent2 : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class ExerciseHubHeader extends StatelessWidget {
  final ExercicioModel exercicio;

  const ExerciseHubHeader({super.key, required this.exercicio});

  @override
  Widget build(BuildContext context) {
    final primaryMuscle = _firstOrFallback(
      exercicio.musculos,
      exercicio.categoria,
    );
    final equipment = _firstOrFallback(exercicio.equipamentos, 'Peso corporal');
    final difficulty = exercicio.dificuldade.trim().isEmpty
        ? 'Nivel livre'
        : exercicio.dificuldade.trim();

    return _HubCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExercicioGifViewer(
            imagem: exercicio.imagem,
            gifPath: exercicio.gifPath,
            titulo: exercicio.nome,
            subtitulo: primaryMuscle,
            height: 246,
            borderRadius: 24,
          ),
          const SizedBox(height: 18),
          Text(
            exercicio.nome,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: Icons.track_changes_rounded,
                label: primaryMuscle,
              ),
              _MetaChip(icon: Icons.construction_rounded, label: equipment),
              _MetaChip(icon: Icons.speed_rounded, label: difficulty),
              _MetaChip(
                icon: Icons.category_rounded,
                label: exercicio.categoria.trim().isEmpty
                    ? 'Geral'
                    : exercicio.categoria.trim(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ExerciseCoachCard extends StatelessWidget {
  final ResumoCargaExercicio? resumo;

  const ExerciseCoachCard({super.key, required this.resumo});

  @override
  Widget build(BuildContext context) {
    final ultima = resumo?.ultimaExecucao;
    final melhorCarga = resumo?.melhorCarga;
    final mediaReps = _mediaRepeticoes(resumo);

    return _SectionCard(
      icon: Icons.auto_awesome_rounded,
      title: 'Coach FitIA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricGrid(
            metrics: [
              _MetricData('Ultima carga', _formatarPeso(ultima?.peso ?? 0)),
              _MetricData(
                'Melhor carga',
                _formatarPeso(melhorCarga?.peso ?? 0),
              ),
              _MetricData(
                'Media reps',
                mediaReps > 0 ? _formatarNumero(mediaReps) : '-',
              ),
              _MetricData('Execucoes', '${resumo?.execucoes.length ?? 0}'),
              _MetricData(
                'Ultima execucao',
                ultima == null ? '-' : _formatarData(ultima.data),
              ),
              _MetricData('Sugestao', _sugestaoCarga(resumo)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withAlpha(45)),
            ),
            child: Text(
              _coachTip(resumo),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseHistoryCard extends StatelessWidget {
  final ResumoCargaExercicio? resumo;

  const ExerciseHistoryCard({super.key, required this.resumo});

  @override
  Widget build(BuildContext context) {
    final recentes = resumo?.recentes ?? const <SerieCargaExercicio>[];

    return _SectionCard(
      icon: Icons.history_rounded,
      title: 'Historico',
      child: recentes.isEmpty
          ? const _EmptyHubState(
              title: 'Sem execucoes recentes',
              text:
                  'As cargas, repeticoes e volumes aparecem aqui depois do treino.',
            )
          : Column(
              children: [
                for (var index = 0; index < recentes.length; index++)
                  _HistoryTile(
                    registro: recentes[index],
                    data: _formatarDataHora(recentes[index].data),
                    volume: _formatarPeso(recentes[index].volume),
                    isLast: index == recentes.length - 1,
                  ),
              ],
            ),
    );
  }
}

class ExerciseStatsCard extends StatelessWidget {
  final ResumoCargaExercicio? resumo;

  const ExerciseStatsCard({super.key, required this.resumo});

  @override
  Widget build(BuildContext context) {
    final melhorCarga = resumo?.melhorCarga;
    final melhorVolume = resumo?.melhorVolume;
    final maiorReps = _maiorRepeticoes(resumo);

    return _SectionCard(
      icon: Icons.insights_rounded,
      title: 'Estatisticas',
      child: _MetricGrid(
        metrics: [
          _MetricData('Maior carga', _formatarPeso(melhorCarga?.peso ?? 0)),
          _MetricData('Maior volume', _formatarPeso(melhorVolume?.volume ?? 0)),
          _MetricData('Mais reps', maiorReps > 0 ? '$maiorReps reps' : '-'),
          _MetricData('Execucoes totais', '${resumo?.execucoes.length ?? 0}'),
          const _MetricData('Descanso medio', 'Sem registro'),
        ],
      ),
    );
  }
}

class ExerciseTechniqueCard extends StatelessWidget {
  final ExercicioModel exercicio;

  const ExerciseTechniqueCard({super.key, required this.exercicio});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.school_rounded,
      title: 'Tecnica',
      child: Column(
        children: [
          _TechniqueBlock(title: 'Como executar', items: _instructions()),
          const SizedBox(height: 12),
          _TechniqueBlock(title: 'Erros comuns', items: _commonMistakes()),
          const SizedBox(height: 12),
          _TechniqueBlock(title: 'Dicas FitIA', items: _fitiaTips()),
          const SizedBox(height: 12),
          const _TechniqueBlock(
            title: 'Respiracao',
            items: [
              'Expire na fase de esforco e inspire no retorno.',
              'Mantenha o tronco firme sem prender o ar por muito tempo.',
            ],
          ),
          const SizedBox(height: 12),
          const _TechniqueBlock(
            title: 'Amplitude',
            items: [
              'Use a maior amplitude confortavel sem perder controle.',
              'Reduza a carga se a tecnica ou a postura quebrar.',
            ],
          ),
        ],
      ),
    );
  }

  List<String> _instructions() {
    return _splitText(
      exercicio.comoExecutar,
      fallback: const [
        'Ajuste postura e pegada antes de iniciar.',
        'Execute a fase principal com controle.',
        'Retorne devagar mantendo tensao no musculo.',
        'Pare se sentir dor articular ou perda de tecnica.',
      ],
    );
  }

  List<String> _commonMistakes() {
    return _splitText(
      exercicio.cuidados,
      fallback: const [
        'Usar impulso para mover a carga.',
        'Perder alinhamento durante a repeticao.',
        'Aumentar peso antes de dominar a amplitude.',
      ],
    );
  }

  List<String> _fitiaTips() {
    final equipment = _firstOrFallback(exercicio.equipamentos, 'peso corporal');
    return [
      'Aqueça com uma serie leve antes das series principais.',
      'Use $equipment com controle e deixe uma margem de 1 a 2 repeticoes.',
      'Registre carga e repeticoes para melhorar as proximas sugestoes.',
    ];
  }
}

class ExerciseMusclesCard extends StatelessWidget {
  final ExercicioModel exercicio;

  const ExerciseMusclesCard({super.key, required this.exercicio});

  @override
  Widget build(BuildContext context) {
    final primary = exercicio.musculos.isEmpty
        ? [exercicio.categoria]
        : exercicio.musculos;
    final secondary = exercicio.musculosSecundarios;
    final synergists = exercicio.tags
        .where((item) => item.trim().isNotEmpty)
        .take(6)
        .toList();

    return _SectionCard(
      icon: Icons.accessibility_new_rounded,
      title: 'Musculos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChipGroup(title: 'Primario', values: primary),
          const SizedBox(height: 12),
          _ChipGroup(
            title: 'Secundario',
            values: secondary.isEmpty ? const ['Sem dados'] : secondary,
          ),
          const SizedBox(height: 12),
          _ChipGroup(
            title: 'Sinergistas',
            values: synergists.isEmpty ? const ['Sem dados'] : synergists,
          ),
        ],
      ),
    );
  }
}

class ExerciseHubExecuteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ExerciseHubExecuteButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Executar agora'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _HubCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(38),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _HubCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;

  const _MetricData(this.label, this.value);
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricData> metrics;

  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width.clamp(132, 190).toDouble(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withAlpha(14)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          metric.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final SerieCargaExercicio registro;
  final String data;
  final String volume;
  final bool isLast;

  const _HistoryTile({
    required this.registro,
    required this.data,
    required this.volume,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withAlpha(14)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(22),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '${registro.series}x',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${registro.cargaFormatada} x ${registro.repeticoes} reps',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              volume,
              style: const TextStyle(
                color: AppColors.accent1,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechniqueBlock extends StatelessWidget {
  final String title;
  final List<String> items;

  const _TechniqueBlock({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          for (var index = 0; index < items.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}.',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    items[index],
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (index != items.length - 1) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final String title;
  final List<String> values;

  const _ChipGroup({required this.title, required this.values});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .where((value) => value.trim().isNotEmpty)
              .map(
                (value) =>
                    _MetaChip(icon: Icons.circle_rounded, label: value.trim()),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _EmptyHubState extends StatelessWidget {
  final String title;
  final String text;

  const _EmptyHubState({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timeline_rounded,
            color: AppColors.textSecondary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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

double _mediaRepeticoes(ResumoCargaExercicio? resumo) {
  final execucoes = resumo?.execucoes ?? const <SerieCargaExercicio>[];
  if (execucoes.isEmpty) return 0;
  final total = execucoes.fold<int>(0, (sum, item) => sum + item.repeticoes);
  return total / execucoes.length;
}

int _maiorRepeticoes(ResumoCargaExercicio? resumo) {
  final execucoes = resumo?.execucoes ?? const <SerieCargaExercicio>[];
  if (execucoes.isEmpty) return 0;
  return execucoes
      .map((item) => item.repeticoes)
      .reduce((a, b) => a > b ? a : b);
}

String _coachTip(ResumoCargaExercicio? resumo) {
  if (resumo == null || !resumo.temHistorico) {
    return 'Primeira referencia deste exercicio. Registre algumas series para o Coach ajustar carga e repeticoes.';
  }

  final evolucao = resumo.evolucaoVolumePercentual;
  if (evolucao > 5) {
    return 'Voce evoluiu ${_formatarNumero(evolucao)}% neste exercicio. Mantenha a tecnica e avance com pequenos aumentos.';
  }
  if (evolucao < -5) {
    return 'Seu volume caiu ${_formatarNumero(evolucao.abs())}%. Considere reduzir a carga e priorizar execucao limpa.';
  }
  return 'Sua performance esta estavel. Tente bater a faixa alta de repeticoes antes de aumentar a carga.';
}

String _sugestaoCarga(ResumoCargaExercicio? resumo) {
  final base = resumo?.melhorCarga?.peso ?? resumo?.ultimaExecucao?.peso ?? 0;
  if (base <= 0) return 'Carga confortavel';
  final sugestao = (base * 1.025 * 2).round() / 2;
  return '${_formatarNumero(sugestao)} kg x 6-8';
}

List<String> _splitText(String text, {required List<String> fallback}) {
  final value = text.trim();
  if (value.isEmpty) return fallback;

  final items = value
      .replaceAll('\r', '\n')
      .replaceAll(';', '\n')
      .replaceAll('. ', '.\n')
      .split('\n')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .take(5)
      .toList();

  return items.isEmpty ? fallback : items;
}

String _firstOrFallback(List<String> values, String fallback) {
  for (final value in values) {
    final clean = value.trim();
    if (clean.isNotEmpty) return clean;
  }
  return fallback.trim().isEmpty ? 'Geral' : fallback.trim();
}

String _formatarData(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year}';
}

String _formatarDataHora(DateTime data) {
  final hora = data.hour.toString().padLeft(2, '0');
  final minuto = data.minute.toString().padLeft(2, '0');
  return '${_formatarData(data)} - $hora:$minuto';
}

String _formatarPeso(double peso) {
  if (peso <= 0) return '-';
  if (peso >= 1000) return '${_formatarNumero(peso / 1000)} t';
  return '${_formatarNumero(peso)} kg';
}

String _formatarNumero(double valor) {
  if (valor == valor.roundToDouble()) return valor.round().toString();
  return valor.toStringAsFixed(1).replaceAll('.', ',');
}
