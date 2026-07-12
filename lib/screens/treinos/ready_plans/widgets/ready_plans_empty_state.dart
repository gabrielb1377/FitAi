import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

class ReadyPlansEmptyState extends StatelessWidget {
  final bool isError;
  final VoidCallback? onRetry;

  const ReadyPlansEmptyState({super.key, this.isError = false, this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (isError) {
      return FitErrorState(
        title: 'Biblioteca indisponivel',
        error: 'Nao foi possivel carregar os planos agora.',
        details: 'Tente novamente quando o backend estiver disponivel.',
        onRetry: onRetry,
      );
    }
    return const FitEmptyState(
      icon: Icons.search_off_rounded,
      title: 'Nenhum plano encontrado',
      description: 'Tente buscar por outro nome ou filtro.',
    );
  }
}
