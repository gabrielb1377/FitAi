import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../showcase_section.dart';

/// Demonstra feedback transitório, loading e estados de conteúdo.
class FeedbackShowcasePage extends StatelessWidget {
  const FeedbackShowcasePage({super.key});

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FitTopBar(
        title: 'Feedback',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FitSpacing.s16),
          children: [
            ShowcaseSection(
              title: 'Transitório',
              child: FitPrimaryButton(
                label: 'Mostrar FitSnackBar',
                onPressed: () => const FitSnackBar(
                  message: 'Alterações salvas.',
                  tone: FitSnackBarTone.success,
                ).show(context),
              ),
            ),
            const SizedBox(height: FitSpacing.s24),
            const ShowcaseSection(
              title: 'Loading',
              child: Column(
                children: [
                  Wrap(
                    spacing: FitSpacing.s20,
                    runSpacing: FitSpacing.s20,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FitLoading.small(label: 'FitLoading'),
                      FitCircularLoading(label: 'FitCircularLoading'),
                    ],
                  ),
                  SizedBox(height: FitSpacing.s20),
                  FitLinearLoading(value: .65, label: 'FitLinearLoading'),
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s24),
            ShowcaseSection(
              title: 'Estados',
              child: Column(
                children: [
                  const FitEmptyState(
                    title: 'Estado vazio',
                    description: 'Nenhum conteúdo disponível.',
                    icon: FitIcons.list,
                  ),
                  const FitDivider(),
                  const FitErrorState(
                    error: 'Não foi possível carregar.',
                    onRetry: _noop,
                  ),
                  const FitDivider(),
                  const FitOfflineState(compact: true, onRetry: _noop),
                  const FitDivider(),
                  const FitSuccessState(
                    title: 'Tudo certo',
                    description: 'A operação foi concluída.',
                  ),
                  const FitDivider(),
                  const FitWarningState(
                    title: 'Atenção',
                    description: 'Revise as informações antes de continuar.',
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
