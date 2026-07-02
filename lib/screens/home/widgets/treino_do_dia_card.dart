import 'package:flutter/material.dart';

import '../../../models/treino_model.dart';
import '../../../services/treino_do_dia_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_components.dart';

class TreinoDoDiaCard extends StatelessWidget {
  final TreinoDoDiaSelecao selecao;
  final bool carregandoTreinos;
  final Future<void> Function(TreinoModel treino) onAbrirTreino;
  final Future<void> Function() onCriarTreino;
  final Future<void> Function() onGerarIa;

  const TreinoDoDiaCard({
    super.key,
    required this.selecao,
    required this.carregandoTreinos,
    required this.onAbrirTreino,
    required this.onCriarTreino,
    required this.onGerarIa,
  });

  @override
  Widget build(BuildContext context) {
    final treino = selecao.treino;

    if (carregandoTreinos && treino == null) {
      return const AppLoading(
        message: 'Preparando seu treino de hoje...',
        gradient: AppColors.gradientWorkout,
      );
    }

    if (treino == null) {
      return AppGradientCard(
        gradient: AppColors.gradientWorkout,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeroTopLine(
              label: 'TREINO DE HOJE',
              icon: Icons.auto_awesome_rounded,
            ),
            const SizedBox(height: 22),
            Text(
              selecao.titulo,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              selecao.descricao,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.45,
              ),
            ),
            if (!selecao.diaDeDescanso) ...[
              const SizedBox(height: 22),
              _CreateWorkoutActions(
                onCriarTreino: onCriarTreino,
                onGerarIa: onGerarIa,
              ),
            ],
          ],
        ),
      );
    }

    final titulo = selecao.diaDeDescanso
        ? 'Dia de recuperação'
        : selecao.treinoConcluidoHoje
        ? 'Treino do dia concluído'
        : treino.nome;
    final subtitulo = selecao.diaDeDescanso
        ? '${selecao.descricao} Sugestão leve: ${treino.nome}.'
        : selecao.treinoConcluidoHoje
        ? '${selecao.descricao} ${treino.exercicios.length} exercícios • ${treino.tempoEstimado} min'
        : 'Hoje é dia de ${treino.nome}.';
    final statusLabel = selecao.diaDeDescanso
        ? 'Recuperação'
        : selecao.treinoConcluidoHoje
        ? 'Concluído'
        : 'Pronto';
    final buttonLabel = selecao.diaDeDescanso
        ? 'Fazer treino leve'
        : selecao.treinoConcluidoHoje
        ? 'Repetir treino'
        : 'Iniciar treino';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onAbrirTreino(treino),
        borderRadius: BorderRadius.circular(22),
        child: AppGradientCard(
          gradient: AppColors.gradientWorkout,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroTopLine(
                label: 'TREINO DE HOJE',
                icon: Icons.fitness_center_rounded,
                trailing: _StatusPill(label: statusLabel),
              ),
              const SizedBox(height: 22),
              Text(
                titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitulo,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              _WorkoutMetaRow(treino: treino),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (selecao.diaDeDescanso)
                    const AppChip(label: 'Recuperação', dark: true),
                  if (selecao.treinoConcluidoHoje)
                    const AppChip(label: 'Concluído hoje', dark: true),
                  AppChip(label: treino.objetivo, dark: true),
                  AppChip(label: treino.nivel, dark: true),
                  if (treino.criadoPorIA)
                    const AppChip(
                      label: 'IA',
                      icon: Icons.auto_awesome_rounded,
                      dark: true,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              AppButton.primary(
                onPressed: () => onAbrirTreino(treino),
                icon: selecao.treinoConcluidoHoje
                    ? Icons.replay_rounded
                    : Icons.play_arrow_rounded,
                label: buttonLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroTopLine extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget? trailing;

  const _HeroTopLine({required this.label, required this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(30),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withAlpha(32)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white70,
              letterSpacing: 1.1,
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(34)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WorkoutMetaRow extends StatelessWidget {
  final TreinoModel treino;

  const _WorkoutMetaRow({required this.treino});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final width = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - 16) / 3;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: width,
              child: _MetaTile(
                icon: Icons.timer_rounded,
                label: 'Tempo',
                value: '${treino.tempoEstimado} min',
              ),
            ),
            SizedBox(
              width: width,
              child: _MetaTile(
                icon: Icons.format_list_bulleted_rounded,
                label: 'Exercícios',
                value: '${treino.exercicios.length}',
              ),
            ),
            SizedBox(
              width: width,
              child: _MetaTile(
                icon: Icons.flag_rounded,
                label: 'Objetivo',
                value: treino.objetivo,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetaTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateWorkoutActions extends StatelessWidget {
  final Future<void> Function() onCriarTreino;
  final Future<void> Function() onGerarIa;

  const _CreateWorkoutActions({
    required this.onCriarTreino,
    required this.onGerarIa,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 460;
        final buttonWidth = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: buttonWidth,
              child: AppButton.primary(
                onPressed: onCriarTreino,
                icon: Icons.add_rounded,
                label: 'Criar treino',
              ),
            ),
            SizedBox(
              width: buttonWidth,
              child: AppButton.secondary(
                onPressed: onGerarIa,
                icon: Icons.auto_awesome_rounded,
                label: 'Gerar com IA',
              ),
            ),
          ],
        );
      },
    );
  }
}
