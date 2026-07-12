import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../../../models/coach_insight_model.dart';

/// Mostra somente o insight principal na Home e abre detalhes ja carregados.
class HomeCoachInsight extends StatelessWidget {
  final Future<List<CoachInsightModel>> insightsFuture;

  const HomeCoachInsight({super.key, required this.insightsFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CoachInsightModel>>(
      future: insightsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const FitSection(
            title: 'Coach FitIA',
            child: FitCard(
              variant: FitCardVariant.outlined,
              child: FitLoading.inline(label: 'Organizando seu insight...'),
            ),
          );
        }
        if (snapshot.hasError) {
          return FitSection(
            title: 'Coach FitIA',
            child: FitCard(
              variant: FitCardVariant.outlined,
              child: Text(
                'Insights indisponiveis agora. Seus dados locais continuam acessiveis.',
                style: context.textTheme.bodyMedium,
              ),
            ),
          );
        }
        final insights = snapshot.data ?? const <CoachInsightModel>[];
        if (insights.isEmpty) {
          return FitSection(
            title: 'Coach FitIA',
            child: FitCard(
              variant: FitCardVariant.outlined,
              child: Text(
                'Seu proximo insight aparecera conforme voce registrar atividades.',
                style: context.textTheme.bodyMedium,
              ),
            ),
          );
        }
        final primary = insights.first;
        return FitSection(
          title: 'Coach FitIA',
          child: FitCard(
            variant: FitCardVariant.outlined,
            leading: const Icon(Icons.auto_awesome_rounded),
            title: primary.titulo,
            trailing: FitBadge.ai(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primary.descricao,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium,
                ),
                const SizedBox(height: FitSpacing.s12),
                FitButton(
                  label: 'Ver detalhes',
                  variant: FitButtonVariant.ghost,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => _showDetails(context, insights),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetails(BuildContext context, List<CoachInsightModel> insights) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(FitSpacing.s20),
          itemCount: insights.length,
          separatorBuilder: (_, _) =>
              const FitDivider(verticalSpacing: FitSpacing.s16),
          itemBuilder: (_, index) {
            final insight = insights[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.titulo,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: FitSpacing.s8),
                Text(
                  insight.descricao,
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
                if (insight.acao.isNotEmpty) ...[
                  const SizedBox(height: FitSpacing.s8),
                  Text(
                    insight.acao,
                    style: Theme.of(sheetContext).textTheme.labelSmall,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
