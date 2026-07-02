import 'package:flutter/material.dart';

import '../../../services/ia_evolutiva_service.dart';
import '../../../services/treino_do_dia_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_components.dart';

class FitiaRecomendacaoCard extends StatelessWidget {
  final TreinoDoDiaSelecao selecao;
  final IaEvolutivaRecomendacao? recomendacao;
  final bool carregandoTreinos;

  const FitiaRecomendacaoCard({
    super.key,
    required this.selecao,
    required this.recomendacao,
    required this.carregandoTreinos,
  });

  @override
  Widget build(BuildContext context) {
    if (carregandoTreinos && recomendacao == null) {
      return const AppLoading(message: 'Ajustando recomendação do FitIA...');
    }

    final recomendacaoFinal = _recomendacaoParaTreinoDoDia(
      selecao,
      recomendacao,
    );

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.tips_and_updates_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INSIGHTS DA IA',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      recomendacaoFinal.titulo,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            recomendacaoFinal.texto,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _intensidadeChip(recomendacaoFinal.intensidade),
              if (recomendacaoFinal.treinoRecomendado != null)
                AppChip(
                  label: recomendacaoFinal.treinoRecomendado!.nome,
                  icon: Icons.fitness_center_rounded,
                ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _mostrarMotivo(context, recomendacaoFinal.motivo),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.help_outline_rounded,
                    size: 16,
                    color: Colors.white38,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Por que essa recomendação?',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

  IaEvolutivaRecomendacao _recomendacaoParaTreinoDoDia(
    TreinoDoDiaSelecao selecao,
    IaEvolutivaRecomendacao? recomendacaoBase,
  ) {
    final treino = selecao.treino;

    if (selecao.treinoConcluidoHoje || selecao.todosTreinosConcluidosHoje) {
      return IaEvolutivaRecomendacao(
        titulo: 'Treino do dia concluído',
        texto:
            'Você já concluiu o treino de hoje. Faça recuperação, alongamento ou caminhada leve.',
        motivo: selecao.motivo,
        intensidade: 'leve',
        treinoRecomendado: treino,
      );
    }

    if (selecao.diaDeDescanso) {
      return IaEvolutivaRecomendacao(
        titulo: 'Dia de recuperação',
        texto: treino == null
            ? 'Hoje é um bom dia para recuperar. Faça alongamento, mobilidade ou caminhada leve.'
            : 'Hoje é dia de recuperação. Se quiser se movimentar, ${treino.nome} é uma boa opção leve.',
        motivo: selecao.motivo,
        intensidade: 'leve',
        treinoRecomendado: treino,
      );
    }

    if (treino != null) {
      return IaEvolutivaRecomendacao(
        titulo: 'Hoje é dia de ${treino.nome}',
        texto:
            'Hoje é dia de ${treino.nome}. Mantenha consistência e conclua todos os exercícios.',
        motivo: selecao.motivo,
        intensidade: recomendacaoBase?.intensidade ?? 'moderado',
        treinoRecomendado: treino,
      );
    }

    return recomendacaoBase ??
        const IaEvolutivaRecomendacao(
          titulo: 'Primeiro passo inteligente',
          texto: 'Crie uma ficha ou gere uma com IA para começar.',
          motivo: 'Ainda não existem treinos disponíveis.',
          intensidade: 'leve',
        );
  }

  Widget _intensidadeChip(String intensidade) {
    final cor = _corIntensidade(intensidade);
    final label = intensidade.isEmpty
        ? 'Moderado'
        : intensidade[0].toUpperCase() + intensidade.substring(1);

    return AppChip(label: label, color: cor, icon: Icons.bolt_rounded);
  }

  Color _corIntensidade(String intensidade) {
    switch (intensidade.toLowerCase()) {
      case 'leve':
        return AppColors.accent1;
      case 'intenso':
        return AppColors.accent2;
      case 'moderado':
      default:
        return AppColors.primary;
    }
  }

  void _mostrarMotivo(BuildContext context, String motivo) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Por que essa recomendação?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          motivo,
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}
