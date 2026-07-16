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
- `catalog/`: página compilável de demonstração, sem rota de produção.

## Uso em novos componentes

Importe o ponto único de entrada:

```dart
import 'package:fitai/design_system/fit_design_system.dart';
```

Use `FitColors`, `FitSpacing`, `FitRadius`, `FitTypography` e `FitDuration`.
Quando houver contexto, `context.fitColors`, `context.fitText` e os helpers de
breakpoint evitam valores locais e leituras ambíguas.

O barrel dos componentes está em `components/components.dart`; o ponto de
entrada `fit_design_system.dart` também o exporta.

## Categorias principais

- Ações: `FitButton`, `FitIconButton` e `FitFeedback`.
- Superfícies: `FitCard`, cards especializados e `FitStatCard`.
- Entrada: `FitSearchField`, `FitTextField`, `FitNumberField`,
  `FitPasswordField` e `FitDropdownField`.
- Estado: `FitLoading`, `FitSkeleton`, `FitEmptyState`, `FitErrorState`,
  `FitOfflineState` e `FitSuccessState`.
- Feedback e overlays: `FitDialog`, `FitConfirmDialog`, `FitBottomSheet` e
  `FitActionSheet`.
- Métricas e progresso: `FitMetric`, `FitMetricRow`, `FitProgressBar`,
  `FitCircularProgress`, `FitStepProgress` e `FitGoalProgress`.

## Catálogo de desenvolvimento

`catalog/design_system_catalog_page.dart` pode ser aberto apenas por uma rota
de desenvolvimento criada em sprint específica. Não o inclua na Bottom
Navigation ou em fluxos de produção. O catálogo não acessa backend, providers
ou serviços de domínio.

## Migração gradual

`AppTheme`, `AppColors`, `AppGradientCard` e demais componentes legados
continuam sendo compatíveis. O app permanece em `AppTheme.dark` até uma sprint
visual aprovada migrar a entrada de tema e cada módulo consumidor.

`FitTheme.dark()` é o tema oficial preparado para as próximas sprints e deve
ser usado em testes e componentes novos, sem alterar telas existentes nesta
etapa.
