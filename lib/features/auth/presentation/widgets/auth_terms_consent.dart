import 'package:flutter/material.dart';

import '../../../../design_system/tokens/fit_colors.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

class AuthTermsConsent extends StatelessWidget {
  const AuthTermsConsent({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Aceito os termos de uso e a politica de privacidade',
      checked: value,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: FitSpacing.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: value,
                onChanged: (checked) => onChanged(checked ?? false),
              ),
              const SizedBox(width: FitSpacing.s4),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: FitSpacing.s12),
                  child: Text(
                    'Aceito os Termos de Uso e a Politica de Privacidade.',
                    style: TextStyle(color: FitColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
