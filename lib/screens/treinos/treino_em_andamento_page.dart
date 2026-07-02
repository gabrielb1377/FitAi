import 'package:flutter/material.dart';
import '../../models/treino_model.dart';

class TreinoEmAndamentoPage extends StatelessWidget {
  final TreinoModel treino;

  const TreinoEmAndamentoPage({
    super.key,
    required this.treino,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(treino.nome),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: treino.exercicios.length,
        itemBuilder: (context, index) {
          final ex = treino.exercicios[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                child: Text("${index + 1}"),
              ),
              title: Text(ex.nome),
              subtitle: Text(ex.categoria),
            ),
          );
        },
      ),
    );
  }
}