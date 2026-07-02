import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class HeaderHome extends StatelessWidget {
  final String nome;
  final int nivel;

  const HeaderHome({super.key, required this.nome, required this.nivel});

  @override
  Widget build(BuildContext context) {
    final primeiroNome = nome.trim().isEmpty ? 'Atleta' : nome.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _horizontalPadding(context),
        MediaQuery.of(context).padding.top + 18,
        _horizontalPadding(context),
        20,
      ),
      child: AnimatedSwitcher(
        duration: AppMotion.normal,
        switchInCurve: AppMotion.curve,
        switchOutCurve: Curves.easeOut,
        child: Row(
          key: ValueKey('$primeiroNome-$nivel-${_saudacao()}'),
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_saudacao()}, $primeiroNome \u{1F44B}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seu painel de evolução para hoje.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    primeiroNome[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              constraints: const BoxConstraints(minHeight: 42),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.primary.withAlpha(70)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Nv. $nivel',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _saudacao() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Bom dia';
    if (hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }
}
