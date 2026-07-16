import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Campo de busca com limpeza, feedback de loading e debounce opcional.
///
/// [onChanged] responde imediatamente. Use [onDebouncedChanged] apenas para
/// consultas custosas. O timer e cancelado em [dispose].
class FitSearchField extends StatefulWidget {
  const FitSearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onDebouncedChanged,
    this.debounceDuration,
    this.onSubmitted,
    this.hintText = 'Buscar',
    this.label,
    this.focusNode,
    this.onClear,
    this.autofocus = false,
    this.readOnly = false,
    this.enabled = true,
    this.isLoading = false,
    this.errorText,
    this.prefixIcon = Icons.search_rounded,
    this.showClearButton = true,
    this.semanticLabel,
  }) : assert(
         debounceDuration == null || onDebouncedChanged != null,
         'onDebouncedChanged e obrigatorio quando debounceDuration for informado.',
       );

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onDebouncedChanged;
  final Duration? debounceDuration;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final String? label;
  final FocusNode? focusNode;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool readOnly;
  final bool enabled;
  final bool isLoading;
  final String? errorText;
  final IconData prefixIcon;
  final bool showClearButton;
  final String? semanticLabel;

  @override
  State<FitSearchField> createState() => _FitSearchFieldState();
}

class _FitSearchFieldState extends State<FitSearchField> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _handleChanged(String value) {
    widget.onChanged?.call(value);
    final duration = widget.debounceDuration;
    if (duration == null) return;
    _debounce?.cancel();
    _debounce = Timer(duration, () => widget.onDebouncedChanged?.call(value));
  }

  void _clear() {
    widget.controller.clear();
    _handleChanged('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;
        final suffix = widget.isLoading
            ? const Padding(
                padding: EdgeInsets.all(FitSpacing.s12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : widget.showClearButton && hasText
            ? IconButton(
                tooltip: 'Limpar busca',
                onPressed: widget.enabled ? _clear : null,
                icon: const Icon(Icons.close_rounded),
              )
            : null;
        return Semantics(
          textField: true,
          label: widget.semanticLabel ?? widget.label ?? widget.hintText,
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            onChanged: _handleChanged,
            onSubmitted: widget.onSubmitted,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hintText,
              errorText: widget.errorText,
              prefixIcon: Icon(widget.prefixIcon),
              suffixIcon: suffix,
              border: const OutlineInputBorder(
                borderRadius: FitRadius.mediumBorder,
              ),
            ),
          ),
        );
      },
    );
  }
}
