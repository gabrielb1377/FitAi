import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../screens/treinos/ready_plans/ready_plans_library_page.dart';

/// PLAN-018 e PLAN-019.
///
/// A biblioteca continua delegando dados, cache offline, favoritos e a previa
/// para o fluxo ja consolidado. Esta moldura conecta a experiencia ao novo
/// App Shell sem duplicar as regras de sincronizacao.
class PlanosReadyLibraryPage extends StatelessWidget {
  const PlanosReadyLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: FitBreakpoints.tablet),
            child: Column(
              children: [
                FitHeader(
                  title: 'Biblioteca de planos',
                  showBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                const Expanded(child: ReadyPlansLibraryPage(embedded: true)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
