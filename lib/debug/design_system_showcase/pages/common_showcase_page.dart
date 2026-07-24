import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../showcase_section.dart';

/// Demonstra os elementos pequenos compartilhados entre módulos.
class CommonShowcasePage extends StatefulWidget {
  const CommonShowcasePage({super.key});

  @override
  State<CommonShowcasePage> createState() => _CommonShowcasePageState();
}

class _CommonShowcasePageState extends State<CommonShowcasePage> {
  bool _selected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FitTopBar(
        title: 'Common',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FitSpacing.s16),
          children: [
            ShowcaseSection(
              title: 'Identidade e status',
              child: Wrap(
                spacing: FitSpacing.s8,
                runSpacing: FitSpacing.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const FitAvatar(name: 'Gabriel FitIA'),
                  FitChip(
                    label: 'Selecionável',
                    selected: _selected,
                    onSelected: (value) => setState(() => _selected = value),
                  ),
                  const FitBadge.ai(),
                  const FitTag(label: 'Intermediário', icon: FitIcons.progress),
                  const FitLabel(text: 'Sincronizado', icon: FitIcons.success),
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s24),
            const ShowcaseSection(
              title: 'Progresso e métricas',
              child: Row(
                children: [
                  FitProgressRing(value: .72),
                  SizedBox(width: FitSpacing.s24),
                  Expanded(
                    child: FitStatistic(
                      label: 'Treinos',
                      value: '12',
                      icon: FitIcons.workout,
                      trend: '+2 esta semana',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s24),
            ShowcaseSection(
              title: 'Estrutura',
              child: Column(
                children: [
                  const FitSectionTitle(
                    title: 'FitSectionTitle',
                    subtitle: 'Cabeçalho reutilizável',
                  ),
                  const FitDivider(),
                  const FitListTile(
                    title: 'FitListTile',
                    subtitle: 'Item acessível e temático',
                    leading: Icon(FitIcons.settings),
                    trailing: Icon(FitIcons.forward),
                    onTap: _noop,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _noop() {}
}
