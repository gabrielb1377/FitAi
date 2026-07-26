# FitIA Design System Flutter

## Sistema oficial

`lib/design_system` e a base oficial do Design System Flutter do FitIA. Ela
centraliza tokens, tema, extensoes, animacoes e a API publica de componentes.
`lib/core/design_system` nao e um segundo tema: ele e uma extensao modular
temporariamente mantida e exposta pela mesma API publica.

Use somente este import em codigo novo:

```dart
import 'package:fitai/design_system/design_system.dart';
```

`fit_design_system.dart` continua disponivel apenas para compatibilidade com
imports existentes. Nao e necessario migrar telas nesta sprint.

## Estrutura

```text
lib/
|- design_system/
|  |- design_system.dart          # API publica oficial
|  |- fit_design_system.dart      # compatibilidade de imports antigos
|  |- tokens/                     # APIs Fit* de fundamentos
|  |- theme/                      # FitTheme e extensoes
|  |- components/                 # componentes Fit existentes
|  |- extensions/
|  |- animations/
|  `- catalog/
`- core/design_system/
   `- components/                 # extensoes modulares exportadas pelo barrel
```

## Tokens e tema

As APIs oficiais sao `FitColors`, `FitTypography`, `FitSpacing`, `FitRadius`,
`FitDuration`, `FitElevation`, `FitOpacity`, `FitBreakpoints`, `FitLayout`,
`FitShadows`, `FitGradients`, `FitIcons` e `FitStates`.

`FitTheme.dark()` e o tema oficial. `AppTheme.dark` continua delegando para
ele, preservando as telas e testes legados. Os tokens em
`D:\FitIA\designs\design-tokens` sao a fonte documental de Design; qualquer
ajuste de valor que mude a interface exige sprint visual, comparacao de
screenshots e aprovacao, portanto nao e feito por este barrel.

## Componentes publicos

O barrel oficial expoe os componentes fundamentais e suas variantes:

- botoes, `FitIconButton` e `FitFAB`;
- cards, chips, badges, progresso e metricas;
- headers, busca, inputs, navegacao inferior e containers de dialog/sheet;
- loading, vazio, erro, offline, sucesso, warning e snackbar;
- componentes de dominio ja publicados pela Component Library.

Componentes recebem dados e callbacks. Eles nao acessam services, providers,
storage, rotas globais ou logica de negocio.

## Compatibilidade legada

`AppTheme`, `AppColors`, `AppRadii`, `AppSpacing`, `AppMotion` e os widgets
`App*` classificados como `LEGACY_IN_USE` permanecem ativos. Eles nao devem ser
removidos, marcados como deprecated ou migrados por busca global.

O mapeamento detalhado esta em [MIGRATION_MAP.md](MIGRATION_MAP.md). Antes de
migrar um consumidor, confirme a equivalencia de parametros, estados, Semantics,
responsividade, offline e referencia visual.

## Regras para novos componentes

1. Verificar se a necessidade ja e atendida por uma API Fit publica.
2. Usar tokens e `ThemeData`, sem valores visuais literais.
3. Manter a API controlada por parametros e callbacks nomeados.
4. Incluir Semantics, tooltip para acoes apenas com icone e asserts quando
   houver combinacoes invalidas.
5. Exportar pelo barrel adequado, documentar e testar antes de reutilizar.
6. Nao criar componente de dominio generico sem padrao repetido em artes
   oficiais.

## Migracao incremental

1. Escolher um modulo ou fluxo pequeno.
2. Mapear a API `App*` para a variante `Fit*` correta.
3. Preservar callbacks, dados e estado real.
4. Executar testes e comparar a tela com a arte oficial.
5. Somente entao remover o consumo legado daquele ponto.

O estado completo da consolidacao e registrado em
`D:\FitIA\docs\UI_ARCHITECTURE_AUDIT.md`,
`D:\FitIA\docs\DUPLICATE_COMPONENTS_MAP.md` e
`D:\FitIA\docs\VISUAL_CONSOLIDATION_PLAN.md`.
