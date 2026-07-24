import 'package:flutter/material.dart';

import '../../../../design_system/components/fit_button.dart';

/// Botão principal para a ação prioritária do contexto.
class FitPrimaryButton extends FitButton {
  const FitPrimaryButton({
    super.key,
    required super.label,
    super.onPressed,
    super.onPressedAsync,
    IconData? icon,
    super.trailingIcon,
    super.size = FitButtonSize.medium,
    bool fullWidth = false,
    bool loading = false,
    super.enabled = true,
    super.semanticLabel,
    super.tooltip,
    super.enableHapticFeedback = false,
  }) : super(
         leadingIcon: icon,
         variant: FitButtonVariant.primary,
         expand: fullWidth,
         isLoading: loading,
       );
}

/// Botão secundário para uma alternativa relevante, sem competir com o CTA.
class FitSecondaryButton extends FitButton {
  const FitSecondaryButton({
    super.key,
    required super.label,
    super.onPressed,
    super.onPressedAsync,
    IconData? icon,
    super.trailingIcon,
    super.size = FitButtonSize.medium,
    bool fullWidth = false,
    bool loading = false,
    super.enabled = true,
    super.semanticLabel,
    super.tooltip,
    super.enableHapticFeedback = false,
  }) : super(
         leadingIcon: icon,
         variant: FitButtonVariant.secondary,
         expand: fullWidth,
         isLoading: loading,
       );
}

/// Botão outlined para ações disponíveis que pedem menor ênfase.
class FitOutlinedButton extends FitButton {
  const FitOutlinedButton({
    super.key,
    required super.label,
    super.onPressed,
    super.onPressedAsync,
    IconData? icon,
    super.trailingIcon,
    super.size = FitButtonSize.medium,
    bool fullWidth = false,
    bool loading = false,
    super.enabled = true,
    super.semanticLabel,
    super.tooltip,
    super.enableHapticFeedback = false,
  }) : super(
         leadingIcon: icon,
         variant: FitButtonVariant.outlined,
         expand: fullWidth,
         isLoading: loading,
       );
}

/// Botão sem superfície para comandos de baixa prioridade.
class FitGhostButton extends FitButton {
  const FitGhostButton({
    super.key,
    required super.label,
    super.onPressed,
    super.onPressedAsync,
    IconData? icon,
    super.trailingIcon,
    super.size = FitButtonSize.medium,
    bool fullWidth = false,
    bool loading = false,
    super.enabled = true,
    super.semanticLabel,
    super.tooltip,
    super.enableHapticFeedback = false,
  }) : super(
         leadingIcon: icon,
         variant: FitButtonVariant.ghost,
         expand: fullWidth,
         isLoading: loading,
       );
}

/// Botão destrutivo. A confirmação da consequência pertence ao chamador.
class FitDangerButton extends FitButton {
  const FitDangerButton({
    super.key,
    required super.label,
    super.onPressed,
    super.onPressedAsync,
    IconData? icon,
    super.trailingIcon,
    super.size = FitButtonSize.medium,
    bool fullWidth = false,
    bool loading = false,
    super.enabled = true,
    super.semanticLabel,
    super.tooltip,
    super.enableHapticFeedback = false,
  }) : super(
         leadingIcon: icon,
         variant: FitButtonVariant.danger,
         expand: fullWidth,
         isLoading: loading,
       );
}

/// Botão com estado de processamento controlado externamente.
class FitLoadingButton extends FitButton {
  const FitLoadingButton({
    super.key,
    required super.label,
    required bool loading,
    super.onPressed,
    super.onPressedAsync,
    IconData? icon,
    super.trailingIcon,
    super.variant = FitButtonVariant.primary,
    super.size = FitButtonSize.medium,
    bool fullWidth = false,
    super.enabled = true,
    super.semanticLabel,
    super.tooltip,
    super.enableHapticFeedback = false,
  }) : super(leadingIcon: icon, expand: fullWidth, isLoading: loading);
}
