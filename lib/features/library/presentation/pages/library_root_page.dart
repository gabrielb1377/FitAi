import 'package:flutter/material.dart';

import '../../../../screens/exercicios/biblioteca_exercicios_page.dart';

/// Adapter incremental para a Biblioteca oficial já existente.
class LibraryRootPage extends StatelessWidget {
  const LibraryRootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BibliotecaExerciciosPage();
  }
}
