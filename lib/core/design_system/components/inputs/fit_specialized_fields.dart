import 'package:flutter/material.dart';

import '../../../../design_system/components/fit_inputs.dart';
import '../../../../design_system/tokens/fit_icons.dart';

/// Campo de e-mail com teclado, autofill e capitalização apropriados.
class FitEmailField extends FitTextField {
  const FitEmailField({
    super.key,
    required super.controller,
    super.label = 'E-mail',
    super.focusNode,
    super.hintText,
    super.helperText,
    super.errorText,
    super.textInputAction = TextInputAction.next,
    super.onChanged,
    super.onSubmitted,
    super.enabled = true,
    super.readOnly = false,
    super.isLoading = false,
    super.semanticLabel,
  }) : super(
         keyboardType: TextInputType.emailAddress,
         prefixIcon: const Icon(FitIcons.email),
         autofillHints: const [AutofillHints.email],
         textCapitalization: TextCapitalization.none,
         autocorrect: false,
         enableSuggestions: false,
       );
}

/// Nome curto para o dropdown oficial, preservando `FitDropdownField`.
class FitDropdown<T> extends FitDropdownField<T> {
  const FitDropdown({
    super.key,
    required super.label,
    required super.items,
    super.value,
    super.onChanged,
    super.helperText,
    super.errorText,
    super.enabled,
    super.isLoading,
  });
}
