import 'package:flutter/material.dart';

import '../../models/exercicio_model.dart';
import '../exercicios/biblioteca_exercicios_page.dart';

class ListaExerciciosPage extends StatelessWidget {
  final String categoria;
  final void Function(ExercicioModel) onSelecionar;

  const ListaExerciciosPage({
    super.key,
    required this.categoria,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return BibliotecaExerciciosPage(
      categoriaInicial: categoria,
      onSelecionar: onSelecionar,
    );
  }
}
