import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';

/// Estrutura rolável comum às páginas de domínio do showcase.
class DomainShowcaseScaffold extends StatelessWidget {
  const DomainShowcaseScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FitTopBar(
        title: title,
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(FitSpacing.s16),
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(height: FitSpacing.s16),
          itemBuilder: (_, index) => children[index],
        ),
      ),
    );
  }
}

/// Estados transversais apresentados ao fim de cada catálogo de domínio.
class DomainShowcaseStates extends StatelessWidget {
  const DomainShowcaseStates({super.key, required this.emptyTitle});

  final String emptyTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const FitLoadingCard(),
        const SizedBox(height: FitSpacing.s12),
        FitEmptyStateCard(
          title: emptyTitle,
          description: 'Estado vazio controlado pela aplicação.',
          icon: FitIcons.list,
        ),
        const SizedBox(height: FitSpacing.s12),
        const FitInfoCard(
          title: 'Falha ao carregar',
          description: 'Estado de erro demonstrativo, sem serviço associado.',
          icon: FitIcons.error,
          tone: FitInfoCardTone.danger,
        ),
      ],
    );
  }
}
