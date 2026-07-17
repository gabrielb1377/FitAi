import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

class HomeOfflineBanner extends StatelessWidget {
  const HomeOfflineBanner({
    super.key,
    required this.lastUpdatedAt,
    required this.onRetry,
  });

  final DateTime? lastUpdatedAt;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final updated = lastUpdatedAt;
    final detail = updated == null
        ? 'Mostrando os dados salvos neste dispositivo.'
        : 'Dados locais atualizados as ${_time(updated)}.';
    return FitOfflineState(
      compact: true,
      title: 'Voce esta offline',
      description: detail,
      retryLabel: 'Atualizar',
      onRetry: onRetry,
    );
  }

  String _time(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
