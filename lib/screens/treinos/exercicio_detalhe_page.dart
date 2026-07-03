import 'package:flutter/material.dart';

import '../../models/exercicio_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/exercicio_gif_viewer.dart';

class ExercicioDetalhePage extends StatelessWidget {
  final ExercicioModel exercicio;
  final VoidCallback? onConcluir;

  const ExercicioDetalhePage({
    super.key,
    required this.exercicio,
    this.onConcluir,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _quickCards(),
                        const SizedBox(height: 18),
                        _section(
                          title: 'Como executar',
                          icon: Icons.playlist_add_check_rounded,
                          child: _steps(_instructions()),
                        ),
                        const SizedBox(height: 14),
                        _section(
                          title: 'Dicas',
                          icon: Icons.tips_and_updates_rounded,
                          child: _paragraph(
                            exercicio.descricao,
                            fallback:
                                'Mantenha o movimento controlado e foque na tecnica antes de aumentar a carga.',
                          ),
                        ),
                        const SizedBox(height: 14),
                        _section(
                          title: 'Erros comuns',
                          icon: Icons.report_problem_rounded,
                          child: _steps(_commonMistakes()),
                        ),
                        const SizedBox(height: 14),
                        _section(
                          title: 'Musculos trabalhados',
                          icon: Icons.accessibility_new_rounded,
                          child: _muscleBlock(),
                        ),
                        const SizedBox(height: 14),
                        _section(
                          title: 'Historico recente',
                          icon: Icons.history_rounded,
                          child: const _EmptyMetric(
                            title: 'Sem historico recente',
                            subtitle:
                                'Ao registrar series neste exercicio, os dados aparecem aqui.',
                          ),
                        ),
                        const SizedBox(height: 14),
                        _section(
                          title: 'Recorde pessoal',
                          icon: Icons.emoji_events_rounded,
                          child: const _EmptyMetric(
                            title: 'Nenhum PR registrado',
                            subtitle:
                                'Complete uma serie com carga para criar sua primeira referencia.',
                          ),
                        ),
                        const SizedBox(height: 18),
                        _actions(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final primaryMuscle = _firstOrFallback(
      exercicio.musculos,
      exercicio.categoria,
    );
    final equipment = _firstOrFallback(exercicio.equipamentos, 'Peso corporal');
    final difficulty = exercicio.dificuldade.trim().isEmpty
        ? 'Nivel livre'
        : exercicio.dificuldade.trim();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Detalhe do exercicio',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ExercicioGifViewer(
                imagem: exercicio.imagem,
                titulo: exercicio.nome,
                subtitulo: primaryMuscle,
                height: 220,
                borderRadius: 26,
              ),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Column(
                  key: ValueKey(exercicio.id),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercicio.nome,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(Icons.fitness_center_rounded, primaryMuscle),
                        _chip(Icons.construction_rounded, equipment),
                        _chip(Icons.speed_rounded, difficulty),
                      ],
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

  Widget _quickCards() {
    final primaryMuscle = _firstOrFallback(
      exercicio.musculos,
      exercicio.categoria,
    );

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _QuickCard(label: 'Series', value: '3', icon: Icons.repeat_rounded),
        _QuickCard(
          label: 'Repeticoes',
          value: '8-12',
          icon: Icons.format_list_numbered_rounded,
        ),
        _QuickCard(label: 'Descanso', value: '60s', icon: Icons.timer_rounded),
        _QuickCard(
          label: 'Principal',
          value: primaryMuscle,
          icon: Icons.track_changes_rounded,
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return AppGradientCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
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
                    fontSize: 16,
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

  Widget _paragraph(String text, {required String fallback}) {
    final value = text.trim().isEmpty ? fallback : text.trim();

    return Text(
      value,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _steps(List<String> items) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _StepRow(number: index + 1, text: items[index]),
          if (index != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _muscleBlock() {
    final primary = exercicio.musculos;
    final secondary = exercicio.musculosSecundarios;
    final equipments = exercicio.equipamentos;
    final tags = exercicio.tags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chipsGroup(
          title: 'Principais',
          values: primary.isEmpty ? [exercicio.categoria] : primary,
        ),
        if (secondary.isNotEmpty) ...[
          const SizedBox(height: 12),
          _chipsGroup(title: 'Secundarios', values: secondary),
        ],
        if (equipments.isNotEmpty) ...[
          const SizedBox(height: 12),
          _chipsGroup(title: 'Equipamentos', values: equipments),
        ],
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          _chipsGroup(title: 'Tags', values: tags),
        ],
      ],
    );
  }

  Widget _chipsGroup({required String title, required List<String> values}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: .2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .where((value) => value.trim().isNotEmpty)
              .map((value) => _plainChip(value.trim()))
              .toList(),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Voltar'),
          ),
        ),
        if (onConcluir != null) ...[
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onConcluir,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Concluir'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 7),
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

  Widget _plainChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  List<String> _instructions() {
    final text = exercicio.comoExecutar.trim();
    if (text.isEmpty) {
      return const [
        'Ajuste sua postura antes de iniciar o movimento.',
        'Execute a fase principal com controle e amplitude segura.',
        'Retorne devagar, mantendo a musculatura sob tensao.',
        'Respire de forma constante e evite compensacoes.',
      ];
    }

    final normalized = text
        .replaceAll('\r', '\n')
        .replaceAll(';', '\n')
        .replaceAll('. ', '.\n');

    final items = normalized
        .split('\n')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .take(6)
        .toList();

    return items.isEmpty ? [text] : items;
  }

  List<String> _commonMistakes() {
    final cuidados = exercicio.cuidados.trim();
    if (cuidados.isNotEmpty) {
      final items = cuidados
          .replaceAll('\r', '\n')
          .replaceAll(';', '\n')
          .replaceAll('. ', '.\n')
          .split('\n')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .take(4)
          .toList();

      if (items.isNotEmpty) return items;
    }

    return const [
      'Usar impulso em vez de controle.',
      'Perder a postura durante as repeticoes.',
      'Aumentar a carga antes de dominar a tecnica.',
    ];
  }

  String _firstOrFallback(List<String> values, String fallback) {
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty) return clean;
    }

    return fallback.trim().isEmpty ? 'Geral' : fallback.trim();
  }
}

class _QuickCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _QuickCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 148),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
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
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(28),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyMetric extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyMetric({required this.title, required this.subtitle});

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
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
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
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
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
