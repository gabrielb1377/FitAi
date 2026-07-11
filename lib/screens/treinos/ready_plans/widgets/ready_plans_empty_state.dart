import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

class ReadyPlansEmptyState extends StatelessWidget {
  final bool isError;
  final VoidCallback? onRetry;

  const ReadyPlansEmptyState({super.key, this.isError = false, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final title = isError ? 'Planos indisponíveis' : 'Nenhum plano encontrado';
    final message = isError
        ? 'Não foi possível carregar os planos agora.'
        : 'Tente buscar por outro nome ou filtro.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.cloud_off_rounded : Icons.search_off_rounded,
              color: AppColors.textHint,
              size: 44,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
