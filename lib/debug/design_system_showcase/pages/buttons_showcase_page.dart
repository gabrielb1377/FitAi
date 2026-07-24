import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../showcase_section.dart';

/// Demonstra todas as APIs públicas do módulo Buttons.
class ButtonsShowcasePage extends StatelessWidget {
  const ButtonsShowcasePage({super.key});

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FitTopBar(
        title: 'Buttons',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FitSpacing.s16),
          children: [
            ShowcaseSection(
              title: 'Variantes',
              child: Wrap(
                spacing: FitSpacing.s8,
                runSpacing: FitSpacing.s8,
                children: [
                  FitPrimaryButton(label: 'Primary', onPressed: _noop),
                  FitSecondaryButton(label: 'Secondary', onPressed: _noop),
                  FitOutlinedButton(label: 'Outlined', onPressed: _noop),
                  FitGhostButton(label: 'Ghost', onPressed: _noop),
                  FitDangerButton(label: 'Danger', onPressed: _noop),
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s24),
            ShowcaseSection(
              title: 'Tamanhos e largura',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FitPrimaryButton(
                    label: 'Small',
                    icon: FitIcons.add,
                    size: FitButtonSize.small,
                    onPressed: _noop,
                  ),
                  const SizedBox(height: FitSpacing.s8),
                  FitPrimaryButton(
                    label: 'Medium',
                    icon: FitIcons.add,
                    size: FitButtonSize.medium,
                    onPressed: _noop,
                  ),
                  const SizedBox(height: FitSpacing.s8),
                  FitPrimaryButton(
                    label: 'Large e largura total',
                    icon: FitIcons.add,
                    size: FitButtonSize.large,
                    fullWidth: true,
                    enableHapticFeedback: true,
                    onPressed: _noop,
                  ),
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s24),
            ShowcaseSection(
              title: 'Estados',
              child: Wrap(
                spacing: FitSpacing.s8,
                runSpacing: FitSpacing.s8,
                children: [
                  const FitLoadingButton(
                    label: 'Loading',
                    loading: true,
                    onPressed: _noop,
                  ),
                  const FitPrimaryButton(
                    label: 'Disabled',
                    enabled: false,
                    onPressed: _noop,
                  ),
                  const FitIconButton(
                    icon: FitIcons.settings,
                    tooltip: 'Configurações',
                    onPressed: _noop,
                  ),
                  const FitFAB(
                    icon: FitIcons.add,
                    tooltip: 'Adicionar',
                    onPressed: _noop,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
