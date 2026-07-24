import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../showcase_section.dart';

/// Demonstra todos os cards genéricos da biblioteca.
class CardsShowcasePage extends StatelessWidget {
  const CardsShowcasePage({super.key});

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FitTopBar(
        title: 'Cards',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FitSpacing.s16),
          children: [
            ShowcaseSection(
              title: 'Superfícies',
              child: Column(
                children: [
                  const FitCard(
                    title: 'FitCard',
                    child: Text('Superfície padrão.'),
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  const FitElevatedCard(
                    title: 'FitElevatedCard',
                    child: Text('Destaque sutil.'),
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  const FitOutlinedCard(
                    title: 'FitOutlinedCard',
                    child: Text('Agrupamento delimitado.'),
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  FitSectionCard(
                    title: 'FitSectionCard',
                    subtitle: 'Seção com ação',
                    action: const Icon(FitIcons.forward),
                    onTap: _noop,
                    child: const Text('Conteúdo da seção.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s24),
            ShowcaseSection(
              title: 'Dados',
              child: Column(
                children: [
                  const FitMetricCard(
                    label: 'Passos',
                    value: '8.420',
                    icon: FitIcons.steps,
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  const FitProgressCard(
                    title: 'Meta semanal',
                    value: '68%',
                    progress: .68,
                    icon: FitIcons.progress,
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  const FitInfoCard(
                    title: 'Insight do Coach',
                    description: 'Seu ritmo está consistente nesta semana.',
                    icon: FitIcons.ai,
                    tone: FitInfoCardTone.info,
                  ),
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s24),
            ShowcaseSection(
              title: 'Estados',
              child: Column(
                children: [
                  const FitEmptyStateCard(
                    title: 'Nenhum item',
                    description: 'Os itens aparecerão aqui.',
                    icon: FitIcons.list,
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  const FitLoadingCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
