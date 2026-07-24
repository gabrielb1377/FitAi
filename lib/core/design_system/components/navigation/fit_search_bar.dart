import '../../../../design_system/components/fit_search_field.dart';

/// Alias contextual do campo de busca para headers e barras de ferramentas.
class FitSearchBar extends FitSearchField {
  const FitSearchBar({
    super.key,
    required super.controller,
    super.onChanged,
    super.onDebouncedChanged,
    super.debounceDuration,
    super.onSubmitted,
    super.hintText,
    super.label,
    super.focusNode,
    super.onClear,
    super.autofocus,
    super.readOnly,
    super.enabled,
    super.isLoading,
    super.errorText,
    super.prefixIcon,
    super.showClearButton,
    super.semanticLabel,
  });
}
