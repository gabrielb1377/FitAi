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

          const SizedBox(height: 10),

          Text(
            treino.descricao,
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 20),

          AppGradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Objetivo",
                  style: Theme.of(context).textTheme.labelLarge,
                ),

                const SizedBox(height: 5),

                Text(treino.objetivo),

                const SizedBox(height: 15),

                Text(
                  "Nível",
                  style: Theme.of(context).textTheme.labelLarge,
                ),

                const SizedBox(height: 5),

                Text(treino.nivel),

                const SizedBox(height: 15),

                Text(
                  "Tempo estimado",
                  style: Theme.of(context).textTheme.labelLarge,
                ),

                const SizedBox(height: 5),

                Text("${treino.tempoEstimado} minutos"),
              ],
            ),
          ),

          const SizedBox(height: 25),

          Text(
            "Exercícios",
            style: Theme.of(context).textTheme.headlineSmall,
          ),

          const SizedBox(height: 15),

          ...treino.exercicios.map((e) {

            return Card(
              child: ListTile(
                leading: const Icon(Icons.fitness_center),

                title: Text(e.nome),

                subtitle: Text(e.categoria),
              ),
            );

          }),

          const SizedBox(height: 40),

          ElevatedButton.icon(
            onPressed: () {

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Treino iniciado!"),
                ),
              );

            },
            icon: const Icon(Icons.play_arrow),
            label: const Text("Iniciar Treino"),
          ),
        ],
      ),
    );
  }
}