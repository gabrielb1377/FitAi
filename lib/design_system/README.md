# FitIA Design System Flutter

Esta pasta contém o mapeamento Flutter das foundations do FitIA Design System
3.0. A fonte de decisão continua em `D:\FitIA\designs\design-system`; o código
daqui oferece tokens, tema e APIs reutilizáveis sem incorporar regras de
negócio.

## Estrutura

- `tokens/`: cores, tipografia, números, spacing, radius, layout, estados,
  elevação, sombras, opacidade, motion, gradientes, ícones e breakpoints.
- `theme/`: `FitTheme` e `ThemeExtension`s para cores de domínio e gradientes.
- `extensions/`: atalhos seguros de `BuildContext` para tema e viewport.
- `components/`: widgets `Fit*` existentes; não foram redesenhados no M02.
- `animations/`: helpers existentes que consomem tokens de motion.
- `catalog/`: demonstração compilável sem rota de produção.

## Ponto de entrada

```dart
import 'package:fitai/design_system/fit_design_system.dart';
```

O barrel exporta somente as APIs públicas do Design System. Componentes devem
consumir nomes semânticos como `FitColors.primary`,
`FitSpacing.sectionGap`, `FitRadius.card`, `FitTypography.heading` e
`FitDuration.feedback`.

Quando houver contexto:

```dart
final colors = context.colors;
final domainColors = context.fitColors;
final gradients = context.fitGradients;
final textTheme = context.fitText;
```

## Tema global

`FitTheme.dark()` é o tema oficial. `AppTheme.dark` aponta para essa mesma
factory para manter os imports existentes. `AppTheme.legacyDark` preserva
temporariamente a configuração estrutural anterior para migração. Como ela
consome aliases atuais, não representa um snapshot visual bit a bit.

Um tema claro não foi inferido. A factory permite adicioná-lo futuramente
quando houver paleta e especificação oficiais.

## Maturidade

- neutros, papéis cromáticos, estados e escala tipográfica são sustentados
  pelo DS3;
- valores cromáticos de domínio permanecem provisórios;
- spacing, radius, grid, elevation, opacidade e motion reutilizam valores
  anteriores como candidatos provisórios;
- gradientes possuem papéis confirmados, porém stops e alpha continuam
  provisórios;
- nenhuma tela foi migrada em massa neste marco.

## Compatibilidade

`AppColors`, `AppRadii`, `AppSpacing`, `AppMotion`, `AppTheme` e widgets
legados continuam disponíveis. Novos arquivos devem usar as APIs `Fit*`.

O mapeamento completo está em
`docs/design_system/FLUTTER_MAPPING.md`; divergências e aliases temporários
estão em `docs/design_system/MIGRATION_NOTES.md`.
