import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';

/// Campo de busca controlado pelo chamador, com limpeza opcional e tema atual.
class FitSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final FocusNode? focusNode;
  final VoidCallback? onClear;
  final bool autofocus;

  const FitSearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText = 'Buscar',
    this.focusNode,
    this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar busca',
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                    onClear?.call();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
          border: const OutlineInputBorder(
            borderRadius: FitRadius.mediumBorder,
          ),
        ),
      ),
    );
  }
}
