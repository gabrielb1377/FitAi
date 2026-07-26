# Migration Map do Design System

## Contrato desta etapa

`lib/design_system` e a base oficial do FitIA. O unico import para codigo novo
e:

```dart
import 'package:fitai/design_system/design_system.dart';
```

`lib/core/design_system` permanece como extensao modular exportada pelo barrel
oficial. `lib/theme` e `lib/widgets` continuam como camada de compatibilidade
para consumidores legados. Nenhuma tela deve misturar uma migracao visual com
esta consolidacao de API.

## Mapa de compatibilidade

| Antigo | Oficial | Status | Proxima acao |
| --- | --- | --- | --- |
| `fit_design_system.dart` | `design_system.dart` | Compatibilidade preservada | Usar o novo import apenas em arquivos novos ou tocados por sprint propria. |
| `AppTheme.dark` | `FitTheme.dark()` | Alias ativo | Manter enquanto telas e testes legados dependem de `AppTheme`. |
| `AppColors` | `FitColors` | Alias ativo | Manter valores e API; migrar consumidor por consumidor. |
| `AppRadii` | `FitRadius` | Alias ativo | Manter ate a migracao visual do modulo correspondente. |
| `AppSpacing` | `FitSpacing` | Alias ativo | Nao trocar valores de telas existentes nesta etapa. |
| `AppMotion` | `FitDuration` | Alias ativo | Manter para animacoes legadas. |
| `AppGradientCard` | `FitCard` ou `FitHeroCard` | Legado em uso | Mapear intencao visual antes de qualquer wrapper ou substituicao. |
| `AppCard` | `FitCard` | Legado em uso | Migrar por variante e validar layout. |
| `AppButton`/`AppPremiumButton` | `FitButton` e variantes | Legado em uso | Preservar assinaturas; migrar apenas em telas aprovadas. |
| `AppChip` | `FitChip`/`FitStatusChip` | Legado em uso | Escolher pelo papel semantico, sem busca e substituicao. |
| `AppTextField` | `FitTextField` | Legado em uso | Preservar teclado, validacao e autofill durante a migracao. |
| `AppLoading`/`AppSkeleton`/`AppEmptyState` | Estados `Fit*` | Legado em uso | Consolidar por fluxo, incluindo offline e erro. |
| `AppBottomSheet`/`AppDialog` | `FitBottomSheet`/`FitDialog` | Legado em uso | Priorizar confirmacoes de risco e manter retorno/callbacks. |

## Tokens

`FitColors`, `FitTypography`, `FitSpacing`, `FitRadius`, `FitDuration`,
`FitElevation`, `FitOpacity`, `FitBreakpoints` e `FitLayout` sao a fonte de
tokens do Flutter. Os JSONs em `D:\FitIA\designs\design-tokens` sao a fonte
documental de Design.

Nesta etapa, valores usados por telas nao foram alterados. Alguns JSONs de
Design ainda divergem de valores ja aplicados pelo app; reconciliar essas
medidas requer uma sprint visual isolada, comparacao de screenshots e aprovacao
de Design. Alterar os valores agora mudaria a aparencia de consumidores ativos.

## Regras para codigo novo

- Importar somente `design_system.dart` para APIs Fit.
- Usar `Fit*`, `ThemeData` e `ColorScheme`; nao criar valores literais visuais.
- Nao importar arquivos internos de `core/design_system` diretamente.
- Nao criar aliases novos em `App*`.
- Nao transformar um componente legado em wrapper Fit sem uma matriz de
  parametros e comparacao visual da tela consumidora.
