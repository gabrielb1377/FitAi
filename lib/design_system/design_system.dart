/// API publica oficial do FitIA Design System.
///
/// Novos arquivos devem importar somente este barrel. Ele expoe tokens, tema,
/// extensoes, animacoes e componentes publicos, incluindo as extensoes
/// modulares compativeis em `lib/core/design_system`.
library;

export '../core/design_system/components/components.dart';
export 'animations/fit_animations.dart';
export 'components/components.dart';
export 'extensions/context_extensions.dart';
export 'theme/fit_theme.dart';
export 'theme/fit_theme_extensions.dart';
export 'tokens/fit_breakpoints.dart';
export 'tokens/fit_colors.dart';
export 'tokens/fit_duration.dart';
export 'tokens/fit_elevation.dart';
export 'tokens/fit_gradients.dart';
export 'tokens/fit_icons.dart';
export 'tokens/fit_layout.dart';
export 'tokens/fit_number_styles.dart';
export 'tokens/fit_opacity.dart';
export 'tokens/fit_radius.dart';
export 'tokens/fit_shadows.dart';
export 'tokens/fit_spacing.dart';
export 'tokens/fit_states.dart';
export 'tokens/fit_typography.dart';
