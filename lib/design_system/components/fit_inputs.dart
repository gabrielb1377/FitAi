import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/fit_icons.dart';
import '../tokens/fit_layout.dart';
import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

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
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.onTap,
    this.semanticLabel,
  }) : assert(maxLines > 0),
       assert(minLines == null || minLines > 0),
       assert(minLines == null || minLines <= maxLines),
       assert(maxLength == null || maxLength > 0);

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
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: semanticLabel ?? label,
      hint: errorText ?? helperText ?? hintText,
      enabled: enabled && !isLoading,
      readOnly: readOnly,
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
        onTap: onTap,
        maxLines: obscureText ? 1 : maxLines,
        minLines: obscureText ? 1 : minLines,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        autofillHints: autofillHints,
        textCapitalization: textCapitalization,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          helperText: helperText,
          errorText: errorText,
          prefixIcon: prefixIcon,
          suffixIcon: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(FitSpacing.s12),
                  child: SizedBox(
                    width: FitLayout.loadingSizeSmall,
                    height: FitLayout.loadingSizeSmall,
                    child: CircularProgressIndicator(
                      strokeWidth: FitLayout.loadingStrokeThin,
                    ),
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
      autofillHints: const [AutofillHints.password],
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      prefixIcon: const Icon(FitIcons.lock),
      suffixIcon: IconButton(
        tooltip: _obscureText ? 'Mostrar senha' : 'Ocultar senha',
        onPressed: widget.enabled && !widget.isLoading
            ? () => setState(() => _obscureText = !_obscureText)
            : null,
        icon: Icon(_obscureText ? FitIcons.visibility : FitIcons.visibilityOff),
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
                  padding: EdgeInsets.all(FitSpacing.s12),
                  child: SizedBox(
                    width: FitLayout.loadingSizeSmall,
                    height: FitLayout.loadingSizeSmall,
                    child: CircularProgressIndicator(
                      strokeWidth: FitLayout.loadingStrokeThin,
                    ),
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
