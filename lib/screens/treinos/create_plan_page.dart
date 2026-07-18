import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';
import '../ai_workout_page.dart';
import 'criar_treino_page.dart';
import 'ready_plans/ready_plans_library_page.dart';

class CreatePlanPage extends StatelessWidget {
  const CreatePlanPage({
    super.key,
    this.initialDestination = CreatePlanDestination.choice,
  });

  final CreatePlanDestination initialDestination;

  @override
  Widget build(BuildContext context) {
    final directPage = switch (initialDestination) {
      CreatePlanDestination.ai => const AIWorkoutPage(),
      CreatePlanDestination.manual => const CriarTreinoPage(),
      CreatePlanDestination.library => const ReadyPlansLibraryPage(),
      CreatePlanDestination.choice => null,
    };
    if (directPage != null) return directPage;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                FitSpacing.s20,
                FitSpacing.s8,
                FitSpacing.s20,
                FitSpacing.s32,
              ),
              children: [
                FitHeader(
                  title: 'Como voce quer criar seu plano?',
                  subtitle: 'Escolha a melhor opcao para voce.',
                  showBackButton: true,
                  onBack: () => Navigator.maybePop(context),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: FitSpacing.s32),
                _CreatePlanChoice(
                  title: 'Plano com IA',
                  description:
                      'Nossa inteligencia artificial cria o plano ideal para seus objetivos e rotina.',
                  icon: Icons.auto_awesome_rounded,
                  badge: const FitBadge.ai(),
                  onTap: () => _open(context, const AIWorkoutPage()),
                ),
                const SizedBox(height: FitSpacing.s16),
                _CreatePlanChoice(
                  title: 'Plano Manual',
                  description:
                      'Monte seu plano do zero, personalizando cada detalhe do seu treino.',
                  icon: Icons.assignment_outlined,
                  onTap: () => _open(context, const CriarTreinoPage()),
                ),
                const SizedBox(height: FitSpacing.s16),
                _CreatePlanChoice(
                  title: 'Importar Plano',
                  description:
                      'Escolha um plano pronto e adicione a estrutura completa ao FitIA.',
                  icon: Icons.cloud_upload_outlined,
                  onTap: () => _open(context, const ReadyPlansLibraryPage()),
                ),
                const SizedBox(height: FitSpacing.s24),
                Align(
                  child: TextButton(
                    onPressed: () => _showHelp(context),
                    child: const Text('Qual opcao e melhor para mim?'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, Widget page) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (!context.mounted || created != true) return;
    Navigator.pop(context, true);
  }

  Future<void> _showHelp(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const FitDialog(
        title: 'Escolha seu caminho',
        message:
            'Use IA para personalizacao guiada, Manual para controle total ou Importar para partir de um plano pronto.',
      ),
    );
  }
}

enum CreatePlanDestination { choice, ai, manual, library }

class _CreatePlanChoice extends StatelessWidget {
  const _CreatePlanChoice({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      variant: FitCardVariant.clickable,
      padding: const EdgeInsets.all(FitSpacing.s20),
      onTap: onTap,
      semanticLabel: '$title. $description',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 112,
            decoration: BoxDecoration(
              color: FitColors.primaryContainer,
              borderRadius: FitRadius.largeBorder,
            ),
            child: Icon(icon, color: FitColors.primary, size: 42),
          ),
          const SizedBox(width: FitSpacing.s20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    ?badge,
                  ],
                ),
                const SizedBox(height: FitSpacing.s8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: FitSpacing.s12),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: FitColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: FitColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
