import 'package:flutter/material.dart';

import '../../../../design_system/tokens/fit_icons.dart';
import '../../../../design_system/tokens/fit_radius.dart';

/// Campo controlado que abre o seletor de data da plataforma.
class FitDatePickerField extends StatelessWidget {
  const FitDatePickerField({
    super.key,
    required this.label,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    this.value,
    this.hintText = 'Selecionar data',
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.semanticLabel,
  });

  final String label;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String hintText;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final String? semanticLabel;

  Future<void> _selectDate(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final candidate = value ?? today;
    final initialDate = candidate.isBefore(firstDate)
        ? firstDate
        : candidate.isAfter(lastDate)
        ? lastDate
        : candidate;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    assert(!lastDate.isBefore(firstDate), 'lastDate deve suceder firstDate.');
    final localizations = MaterialLocalizations.of(context);
    final visibleValue = value == null
        ? hintText
        : localizations.formatMediumDate(value!);
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      value: value == null ? null : visibleValue,
      child: InkWell(
        onTap: enabled ? () => _selectDate(context) : null,
        borderRadius: FitRadius.mediumBorder,
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(
            labelText: label,
            helperText: helperText,
            errorText: errorText,
            enabled: enabled,
            suffixIcon: const Icon(FitIcons.calendar),
          ),
          child: Text(
            visibleValue,
            style: value == null
                ? Theme.of(context).inputDecorationTheme.hintStyle
                : Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

/// Campo controlado que abre o seletor de horário da plataforma.
class FitTimePickerField extends StatelessWidget {
  const FitTimePickerField({
    super.key,
    required this.label,
    required this.onChanged,
    this.value,
    this.hintText = 'Selecionar horário',
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.semanticLabel,
  });

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;
  final String hintText;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final String? semanticLabel;

  Future<void> _selectTime(BuildContext context) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: value ?? TimeOfDay.now(),
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final visibleValue = value == null
        ? hintText
        : MaterialLocalizations.of(context).formatTimeOfDay(value!);
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      value: value == null ? null : visibleValue,
      child: InkWell(
        onTap: enabled ? () => _selectTime(context) : null,
        borderRadius: FitRadius.mediumBorder,
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(
            labelText: label,
            helperText: helperText,
            errorText: errorText,
            enabled: enabled,
            suffixIcon: const Icon(FitIcons.time),
          ),
          child: Text(
            visibleValue,
            style: value == null
                ? Theme.of(context).inputDecorationTheme.hintStyle
                : Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
