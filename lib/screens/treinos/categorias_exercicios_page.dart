import 'package:flutter/material.dart';

import '../../models/exercicio_model.dart';
import '../exercicios/biblioteca_exercicios_page.dart';

class CategoriasExerciciosPage extends StatelessWidget {
  final void Function(ExercicioModel) onSelecionar;

  const CategoriasExerciciosPage({super.key, required this.onSelecionar});

  @override
  Widget build(BuildContext context) {
    return BibliotecaExerciciosPage(onSelecionar: onSelecionar);
  }
}
