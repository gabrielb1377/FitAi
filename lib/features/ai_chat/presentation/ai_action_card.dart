import 'dart:async';
import 'package:flutter/material.dart';
import '../../../design_system/fit_design_system.dart';
import '../../../data/exercicios/exercicios.dart';
import '../application/ai_action_controller.dart';
import '../domain/ai_action_models.dart';

/// Functional preview and explicit consent, using the existing Fit components.
class AiActionCard extends StatelessWidget {
  const AiActionCard({
    super.key,
    required this.proposal,
    required this.controller,
  });
  final AiActionProposal proposal;
  final AiActionController controller;
  String _label(Object? value) =>
      bancoExercicios.where((e) => e.id == value).firstOrNull?.nome ??
      value?.toString() ??
      '';
  @override
  Widget build(BuildContext context) {
    final action = controller.current(proposal),
        busy = controller.isBusy(proposal.id);
    final saved = controller.saved(proposal.id);
    final preview = action.preview;
    final status = action.status == 'EXECUTED'
        ? 'Alteracao sincronizada e verificada'
        : saved
        ? 'Salvo neste dispositivo; sincronizacao pendente'
        : action.status == 'CANCELLED'
        ? 'Sugestao cancelada'
        : action.status == 'CONFIRMED'
        ? 'Confirmacao recebida; aplicacao ainda pendente'
        : action.status == 'VALIDATED'
        ? 'Recomendacao da IA; aguardando sua confirmacao'
        : 'Sugestao indisponivel';
    return Padding(
      padding: const EdgeInsets.only(bottom: FitSpacing.s12),
      child: FitCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(switch (action.type) {
              'REPLACE_EXERCISE' => 'Substituir exercicio',
              'ADD_EXERCISE_TO_PLAN' => 'Adicionar ao plano',
              'USE_GENERATED_WORKOUT' => 'Usar treino gerado',
              _ => 'Sugestao',
            }, style: context.textTheme.titleMedium),
            const SizedBox(height: FitSpacing.s8),
            if (preview['before'] != null)
              Text(
                'Antes: ${_label(preview['before'])}',
                style: context.textTheme.bodyMedium,
              ),
            if (preview['after'] != null)
              Text(
                'Depois: ${_label(preview['after'])}',
                style: context.textTheme.bodyLarge,
              ),
            for (final line in preview['details'] as List? ?? const [])
              Text(line.toString(), style: context.textTheme.bodySmall),
            const SizedBox(height: FitSpacing.s8),
            Text(action.explanation, style: context.textTheme.bodyMedium),
            Semantics(
              liveRegion: true,
              child: Text(status, style: context.textTheme.bodySmall),
            ),
            if (controller.error(action.id) != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  controller.error(action.id)!,
                  style: context.textTheme.bodyMedium,
                ),
              ),
            if (['VALIDATED', 'CONFIRMED'].contains(action.status)) ...[
              const SizedBox(height: FitSpacing.s12),
              FitPrimaryButton(
                label: saved
                    ? 'Verificar sincronizacao'
                    : action.status == 'CONFIRMED'
                    ? 'Continuar aplicacao'
                    : 'Confirmar alteracao',
                loading: busy,
                onPressed: busy
                    ? null
                    : () => unawaited(controller.confirm(action)),
              ),
              if (action.status == 'VALIDATED')
                FitGhostButton(
                  label: 'Cancelar sugestao',
                  onPressed: busy
                      ? null
                      : () => unawaited(controller.cancel(action)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
