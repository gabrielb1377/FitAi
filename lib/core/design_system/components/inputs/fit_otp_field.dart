import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/tokens/fit_typography.dart';

/// Campo de código de uso único com comprimento definido pelo fluxo.
class FitOTPField extends StatelessWidget {
  const FitOTPField({
    super.key,
    required this.controller,
    required this.length,
    this.label = 'Código de verificação',
    this.onChanged,
    this.onCompleted,
    this.enabled = true,
    this.autofocus = false,
    this.obscureText = false,
    this.errorText,
    this.semanticLabel,
  }) : assert(length > 0);

  final TextEditingController controller;
  final int length;
  final String label;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool enabled;
  final bool autofocus;
  final bool obscureText;
  final String? errorText;
  final String? semanticLabel;

  void _handleChanged(String value) {
    onChanged?.call(value);
    if (value.length == length) onCompleted?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: semanticLabel ?? label,
      child: TextField(
        controller: controller,
        enabled: enabled,
        autofocus: autofocus,
        obscureText: obscureText,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        textAlign: TextAlign.center,
        style: FitTypography.metricSmall,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(length),
        ],
        onChanged: _handleChanged,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          counterText: '',
        ),
      ),
    );
  }
}
