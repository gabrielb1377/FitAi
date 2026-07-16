# FitIA Design System

Esta pasta contém a infraestrutura visual usada gradualmente pelo Flutter. Ela
não autoriza a migração automática das telas existentes.

## Estrutura

- `tokens/`: cores, tipografia, espaçamento, raios, sombras, opacidade,
  durações e breakpoints.
- `theme/`: `FitTheme` e extensões semânticas que complementam o `ColorScheme`.
- `extensions/`: atalhos seguros de `BuildContext` para tema, tokens e viewport.
- `components/`: widgets `Fit*` reutilizáveis.
- `animations/`: helpers de movimento curto e acessível.

## Uso em novos componentes

Importe o ponto único de entrada:

```dart
import 'package:fitai/design_system/fit_design_system.dart';
```

Use `FitColors`, `FitSpacing`, `FitRadius`, `FitTypography` e `FitDuration`.
Quando houver contexto, `context.fitColors`, `context.fitText` e os helpers de
breakpoint evitam valores locais e leituras ambíguas.

## Migração gradual

`AppTheme`, `AppColors`, `AppGradientCard` e demais componentes legados
continuam sendo compatíveis. O app permanece em `AppTheme.dark` até uma sprint
visual aprovada migrar a entrada de tema e cada módulo consumidor.

`FitTheme.dark()` é o tema oficial preparado para as próximas sprints e deve
ser usado em testes e componentes novos, sem alterar telas existentes nesta
etapa.
