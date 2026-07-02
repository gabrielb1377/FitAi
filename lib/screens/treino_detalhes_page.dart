import 'package:flutter/material.dart';

import '../models/treino_model.dart';
import '../theme/app_theme.dart';

class TreinoDetalhesPage extends StatelessWidget {
  final TreinoModel treino;

  const TreinoDetalhesPage({
    super.key,
    required this.treino,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(treino.nome),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            treino.nome,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            treino.descricao,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          AppGradientCard(
            child: Row(
              children: [
                Expanded(
                  child: AppStatChip(
                    label: 'Objetivo',
                    value: treino.objetivo,
                    icon: Icons.flag,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppStatChip(
                    label: 'Tempo',
                    value: '${treino.tempoEstimado}m',
                    icon: Icons.timer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Exercícios',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          ...treino.exercicios.map((exercicio) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(exercicio.nome),
                subtitle: Text(exercicio.categoria),
              ),
            );
          }),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Treino iniciado!'),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar Treino'),
          ),
        ],
      ),
    );
  }
}
