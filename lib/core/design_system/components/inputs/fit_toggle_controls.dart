import 'package:flutter/material.dart';

/// Checkbox controlado para aceite ou seleção múltipla.
class FitCheckbox extends StatelessWidget {
  const FitCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.enabled = true,
    this.semanticLabel,
  });

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      enabled: enabled,
      label: semanticLabel ?? label,
      child: CheckboxListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        title: Text(label),
        subtitle: description == null ? null : Text(description!),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

/// Switch controlado para preferências binárias imediatas.
class FitSwitch extends StatelessWidget {
  const FitSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.enabled = true,
    this.semanticLabel,
  });

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel ?? label,
      child: SwitchListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        title: Text(label),
        subtitle: description == null ? null : Text(description!),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

/// Opção de escolha única controlada por valor e grupo externos.
class FitRadio<T> extends StatelessWidget {
  const FitRadio({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.description,
    this.enabled = true,
    this.semanticLabel,
  });

  final String label;
  final String? description;
  final T value;
  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value == groupValue,
      enabled: enabled,
      label: semanticLabel ?? label,
      child: RadioGroup<T>(
        groupValue: groupValue,
        onChanged: enabled ? onChanged : (_) {},
        child: RadioListTile<T>(
          value: value,
          enabled: enabled,
          title: Text(label),
          subtitle: description == null ? null : Text(description!),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
