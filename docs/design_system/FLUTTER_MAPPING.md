# Flutter Mapping — FitIA Design System 3.0

## Objetivo

Mapear os tokens documentais de `D:\FitIA\designs\design-system` para as APIs
Flutter públicas em `lib/design_system`. O nome semântico é o contrato; valores
`PROVISÓRIO` e `A VALIDAR` podem mudar após medição sem renomear a intenção.

## Arquitetura adotada

O projeto já possuía `lib/design_system`. Essa estrutura foi preservada para
evitar uma segunda árvore em `lib/core/design_system` e imports duplicados.

Ponto público:

```dart
import 'package:fitai/design_system/fit_design_system.dart';
```

## Cores

| Token documental | Classe Flutter | Propriedade | Status |
| --- | --- | --- | --- |
| `palette.neutral.1000` | `_FitPalette` | `neutral1000` | `CONFIRMADO`, interno |
| `palette.neutral.950` | `_FitPalette` | `neutral950` | `CONFIRMADO`, interno |
| `palette.neutral.900` | `_FitPalette` | `neutral900` | `CONFIRMADO`, interno |
| `palette.neutral.850` | `_FitPalette` | `neutral850` | `CONFIRMADO`, interno |
| `palette.neutral.800` | `_FitPalette` | `neutral800` | `CONFIRMADO`, interno |
| `palette.neutral.700` | `_FitPalette` | `neutral700` | `CONFIRMADO`, interno |
| `palette.neutral.600` | `_FitPalette` | `neutral600` | `CONFIRMADO`, interno |
| `palette.neutral.300` | `_FitPalette` | `neutral300` | `PROVISÓRIO`, interno |
| `palette.neutral.200` | `_FitPalette` | `neutral200` | `CONFIRMADO`, interno |
| `palette.neutral.0` | `_FitPalette` | `neutral0` | `CONFIRMADO`, interno |
| `color.background.canvas` | `FitColors` | `background` | `CONFIRMADO` |
| `color.background.subtle` | `FitColors` | `backgroundSubtle` | `CONFIRMADO` |
| `color.surface.default` | `FitColors` | `surface` | `CONFIRMADO` |
| `color.surface.raised` | `FitColors` | `surfaceRaised` | `CONFIRMADO` |
| `color.card.default` | `FitColors` | `card` | `CONFIRMADO` |
| `color.card.inner` | `FitColors` | `cardInner` | `CONFIRMADO` |
| `color.border.subtle` | `FitColors` | `borderSubtle` | `CONFIRMADO` |
| `color.text.primary` | `FitColors` | `textPrimary` | `CONFIRMADO` |
| `color.text.secondary` | `FitColors` | `textSecondary` | `CONFIRMADO` |
| `color.text.tertiary` | `FitColors` | `textTertiary` | `PROVISÓRIO` |
| `color.text.disabled` | `FitColors` | `textDisabled` | `A VALIDAR` |
| `color.primary.default` | `FitColors` | `primary` | papel `CONFIRMADO`, valor `PROVISÓRIO` |
| `color.primary.muted` | `FitColors` | `primaryMuted` | `PROVISÓRIO` |
| `color.primary.emphasis` | `FitColors` | `primaryEmphasis` | `PROVISÓRIO` |
| `color.text.on-primary` | `FitColors` | `onPrimary` | `PROVISÓRIO`, contraste medido |
| `color.ai.default` | `FitColors` | `ai` | papel `CONFIRMADO`, valor `PROVISÓRIO` |
| `color.info.default` | `FitColors` | `info` | papel `CONFIRMADO`, valor `PROVISÓRIO` |
| `color.success.default` | `FitColors` | `success` | papel `CONFIRMADO`, valor `PROVISÓRIO` |
| `color.warning.default` | `FitColors` | `warning` | papel `CONFIRMADO`, valor `PROVISÓRIO` |
| `color.error.default` | `FitColors` | `error` | papel `CONFIRMADO`, valor `PROVISÓRIO` |
| `color.energy.default` | `FitColors` | `energy` | papel `CONFIRMADO`, valor `PROVISÓRIO` |
| `color.xp.default` | `FitColors` | `xp` | `PROVISÓRIO` |
| `color.overlay.scrim` | `FitColors` | `overlay` | base `CONFIRMADA`, alpha `A VALIDAR` |
| `color.surface.selected` | `FitColors` | `surfaceSelected` | `PROVISÓRIO` |
| `color.primary.pressed` | `FitColors` | `primaryPressed` | `A VALIDAR` |
| `color.primary.focus` | `FitColors` | `focus` | `A VALIDAR` |
| `color.primary.disabled` | `FitColors` | `surfaceDisabled` | `A VALIDAR` |

Não existe `FitColors.accent`: `DS-013` determina acentos por domínio.

## Gradientes

| Token documental | Classe Flutter | Propriedade | Status |
| --- | --- | --- | --- |
| `gradient.action.primary` | `FitGradients` | `actionPrimary` | `PROVISÓRIO` |
| `gradient.media.scrim` | `FitGradients` | `mediaScrim` | estrutura `CONFIRMADA`, valores `A VALIDAR` |
| `gradient.chart.area` | `FitGradients` | `chartArea` | estrutura `CONFIRMADA`, valores `A VALIDAR` |
| `gradient.glow.contextual.ai` | `FitGradients` | `aiGlow` | `PROVISÓRIO` |
| `gradient.glow.contextual.premium` | `FitGradients` | `premiumGlow` | `PROVISÓRIO` |
| `gradient.surface.depth` | `FitGradients` | `surfaceDepth` | `PROVISÓRIO` |
| gradientes no tema | `FitThemeGradients` | todas as propriedades | `PROVISÓRIO` |

Gradientes `legacy*` existem somente para compatibilidade e não são tokens DS3.

## Tipografia

| Token documental | Classe Flutter | Propriedade | Status |
| --- | --- | --- | --- |
| `text.display` | `FitTypography` | `display` | papel `CONFIRMADO`, tamanho `A VALIDAR` |
| `text.heading` | `FitTypography` | `heading` | papel `CONFIRMADO`, tamanho `A VALIDAR` |
| `text.title` | `FitTypography` | `title` | papel `CONFIRMADO`, tamanho `A VALIDAR` |
| `text.subtitle` | `FitTypography` | `subtitle` | papel `CONFIRMADO`, tamanho `A VALIDAR` |
| `text.body` | `FitTypography` | `body` | papel `CONFIRMADO`, tamanho `A VALIDAR` |
| `text.label` | `FitTypography` | `label` | papel `CONFIRMADO`, tamanho `A VALIDAR` |
| `text.caption` | `FitTypography` | `caption` | papel `CONFIRMADO`, tamanho `A VALIDAR` |
| `text.button` | `FitTypography` | `button` | papel `CONFIRMADO`, tamanho `A VALIDAR` |
| `text.chip` | `FitTypography` | `chip` | papel `CONFIRMADO`, tamanho `A VALIDAR` |
| `text.navigation` | `FitTypography` | `navigation` | papel `CONFIRMADO`, tamanho `A VALIDAR` |
| `text.metric` | `FitTypography` | `metric` | papel `CONFIRMADO`, tamanho `A VALIDAR` |
| `text.metric.small` | `FitTypography` | `metricSmall` | papel `CONFIRMADO`, tamanho `A VALIDAR` |
| `text.overline` | `FitTypography` | `overline` | papel `CONFIRMADO`, tamanho `A VALIDAR` |
| `text.timer` | `FitNumberStyles` | `timer` | `PROVISÓRIO` |
| `text.pace` | `FitNumberStyles` | `pace` | `PROVISÓRIO` |
| números de carga | `FitNumberStyles` | `load` | `PROVISÓRIO` |
| `text.percentage` | `FitNumberStyles` | `progress` e `percentage` | `PROVISÓRIO` |
| `text.data.table` | `FitNumberStyles` | `table` | `PROVISÓRIO` |
| `text.unit` | `FitNumberStyles` | `unit` | `CONFIRMADO` como papel |
| escala Material | `FitTypography` | `textTheme` | `PROVISÓRIO` |

Nenhuma fonte externa foi adicionada. O fallback da plataforma continua ativo.

## Spacing e layout

| Token documental | Classe Flutter | Propriedade | Status |
| --- | --- | --- | --- |
| escala mínima | `FitSpacing` | `s2` a `s64` | `PROVISÓRIO` |
| espaçamento mínimo | `FitSpacing` | `minimum` | `PROVISÓRIO` |
| pequeno | `FitSpacing` | `small` | `PROVISÓRIO` |
| médio | `FitSpacing` | `medium` | `PROVISÓRIO` |
| grande | `FitSpacing` | `large` | `PROVISÓRIO` |
| muito grande | `FitSpacing` | `extraLarge` e `huge` | `PROVISÓRIO` |
| margem de tela | `FitSpacing` | `screenMargin` | `PROVISÓRIO` |
| gap de seção | `FitSpacing` | `sectionGap` | `PROVISÓRIO` |
| padding de card | `FitSpacing` | `cardPadding` | `PROVISÓRIO` |
| gap de lista | `FitSpacing` | `listGap` | `PROVISÓRIO` |
| dimensões de controle | `FitLayout` | propriedades semânticas | `PROVISÓRIO` |
| breakpoints | `FitBreakpoints` | `mobile`, `tablet`, `largeTablet` | `A VALIDAR` |

## Radius

| Token documental | Classe Flutter | Propriedade | Status |
| --- | --- | --- | --- |
| controle pequeno | `FitRadius` | `controlSmall` | `PROVISÓRIO` |
| input | `FitRadius` | `input` | `PROVISÓRIO` |
| card | `FitRadius` | `card` | `PROVISÓRIO` |
| card destacado | `FitRadius` | `cardHighlighted` | `PROVISÓRIO` |
| dialog | `FitRadius` | `dialog` | `PROVISÓRIO` |
| bottom sheet | `FitRadius` | `bottomSheet` | `PROVISÓRIO` |
| pill | `FitRadius` | `pill` | `PROVISÓRIO` |
| circular | `FitRadius` | `circular` | `PROVISÓRIO` |

## Elevation e sombras

| Token documental | Classe Flutter | Propriedade | Status |
| --- | --- | --- | --- |
| background | `FitElevation` | `background` | `PROVISÓRIO` |
| surface | `FitElevation` | `surface` | `PROVISÓRIO` |
| card | `FitElevation` | `card` | `PROVISÓRIO` |
| card elevado | `FitElevation` | `cardRaised` | `PROVISÓRIO` |
| controle flutuante | `FitElevation` | `floatingControl` | `PROVISÓRIO` |
| bottom sheet | `FitElevation` | `bottomSheet` | `PROVISÓRIO` |
| dialog | `FitElevation` | `dialog` | `PROVISÓRIO` |
| overlay | `FitElevation` | `overlay` | `PROVISÓRIO` |
| sombras base | `FitShadows` | `none`, `low`, `medium`, `high` | `A VALIDAR` |

O tema combina superfície, borda e sombra; sombra preta não comunica elevação
isoladamente.

## Motion

| Token documental | Classe Flutter | Propriedade | Status |
| --- | --- | --- | --- |
| instant | `FitDuration` | `instant` | `PROVISÓRIO` |
| `motion.duration.fast` | `FitDuration` | `fast` | `A VALIDAR` |
| `motion.duration.normal` | `FitDuration` | `normal` | `A VALIDAR` |
| `motion.duration.slow` | `FitDuration` | `slow` | `A VALIDAR` |
| page transition | `FitDuration` | `pageTransition` | `A VALIDAR` |
| bottom sheet | `FitDuration` | `bottomSheet` | `A VALIDAR` |
| fade | `FitDuration` | `fade` | `A VALIDAR` |
| scale | `FitDuration` | `scale` | `A VALIDAR` |
| feedback pressionado | `FitDuration` | `pressed` | `A VALIDAR` |
| progresso | `FitDuration` | `progress` | `A VALIDAR` |
| `motion.curve.standard` | `FitDuration` | `standardCurve` | `A VALIDAR` |
| `motion.curve.enter` | `FitDuration` | `enterCurve` | `A VALIDAR` |
| `motion.curve.exit` | `FitDuration` | `exitCurve` | `A VALIDAR` |
| compatibilidade `AppMotion` | `FitDuration` | `legacyAppFast`, `legacyAppNormal`, `legacyAppSlow` | temporário |

Nenhuma animação nova foi implementada no M02.

## Estados

| Token documental | Classe Flutter | Propriedade | Status |
| --- | --- | --- | --- |
| default | `FitStateTokens` | `defaultSurface` | `CONFIRMADO` como papel |
| pressed | `FitStateTokens` | `pressedSurface` | `A VALIDAR` |
| focused | `FitStateTokens` | `focusedBorder` | `A VALIDAR` |
| selected | `FitStateTokens` | `selectedSurface` | `PROVISÓRIO` |
| disabled | `FitStateTokens` | `disabledSurface`, `disabledContent` | `A VALIDAR` |
| loading | `FitStateTokens` | `loading` | `CONFIRMADO` como papel |
| success | `FitStateTokens` | `success` | `CONFIRMADO` como papel |
| warning | `FitStateTokens` | `warning` | `CONFIRMADO` como papel |
| error | `FitStateTokens` | `error` | `CONFIRMADO` como papel |
| locked | `FitStateTokens` | `locked` | `CONFIRMADO` como papel |
| premium | `FitStateTokens` | `premium` | `CONFIRMADO` como papel |

Estados interativos reutilizam `WidgetState`; não foi criada uma enumeração
global sem comportamento.

## Tema

| Token documental | Classe Flutter | Propriedade | Status |
| --- | --- | --- | --- |
| tema escuro | `FitTheme` | `dark()` | oficial |
| cores Material | `FitColors` | `colorScheme` | oficial, valores por maturidade |
| cores de domínio | `FitSemanticColors` | extensão `ThemeData` | oficial |
| gradientes | `FitThemeGradients` | extensão `ThemeData` | `PROVISÓRIO` |
| compatibilidade | `AppTheme` | `dark` | alias oficial |
| configuração estrutural legada | `AppTheme` | `legacyDark` | temporário |

`FitTheme.dark()` configura ColorScheme, TextTheme, superfícies, navegação,
inputs, dialogs, bottom sheets, snackbars, indicadores, sliders, switches,
checkboxes e radios.
