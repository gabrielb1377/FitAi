import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';

/// Campo base controlado externamente. Controllers e foco pertencem ao
/// chamador, nunca sao criados dentro do componente.
class FitTextField extends StatelessWidget {
  const FitTextField({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
    this.hintText,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.isLoading = false,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.semanticLabel,
  });

  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final bool isLoading;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: semanticLabel ?? label,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled && !isLoading,
        readOnly: readOnly,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        maxLines: obscureText ? 1 : maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          helperText: helperText,
          errorText: errorText,
          prefixIcon: prefixIcon,
          suffixIcon: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : suffixIcon,
          border: const OutlineInputBorder(
            borderRadius: FitRadius.mediumBorder,
          ),
        ),
      ),
    );
  }
}

class FitNumberField extends FitTextField {
  const FitNumberField({
    super.key,
    required super.controller,
    required super.label,
    super.focusNode,
    super.hintText,
    super.helperText,
    super.errorText,
    super.textInputAction,
    super.onChanged,
    super.onSubmitted,
    super.enabled,
    super.readOnly,
    super.isLoading,
    super.prefixIcon,
    super.suffixIcon,
    super.semanticLabel,
  }) : super(
         keyboardType: const TextInputType.numberWithOptions(decimal: true),
       );
}

class FitPasswordField extends StatefulWidget {
  const FitPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
    this.hintText,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.isLoading = false,
  });

  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool isLoading;

  @override
  State<FitPasswordField> createState() => _FitPasswordFieldState();
}

class _FitPasswordFieldState extends State<FitPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return FitTextField(
      controller: widget.controller,
      label: widget.label,
      focusNode: widget.focusNode,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: widget.enabled,
      isLoading: widget.isLoading,
      obscureText: _obscureText,
      textInputAction: TextInputAction.done,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: IconButton(
        tooltip: _obscureText ? 'Mostrar senha' : 'Ocultar senha',
        onPressed: widget.enabled && !widget.isLoading
            ? () => setState(() => _obscureText = !_obscureText)
            : null,
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
    );
  }
}

class FitDropdownField<T> extends StatelessWidget {
  const FitDropdownField({
    super.key,
    required this.label,
    required this.items,
    this.value,
    this.onChanged,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.isLoading = false,
  });

  final String label;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: enabled && !isLoading ? onChanged : null,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          errorText: errorText,
          suffixIcon: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
          border: const OutlineInputBorder(
            borderRadius: FitRadius.mediumBorder,
          ),
        ),
      ),
    );
  }
}
