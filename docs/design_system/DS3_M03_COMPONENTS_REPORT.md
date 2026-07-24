# DS3.0-M03 — Component Library Flutter

## Status

Implementação concluída em 2026-07-24.

O escopo foi restrito à biblioteca reutilizável, showcase isolado,
documentação, testes e centralização dos tokens consumidos. Nenhuma tela do
produto, regra de negócio, rota principal, provider, service, backend ou
contrato de API foi alterado.

## Arquitetura adotada

A arquitetura definida no M02 foi preservada:

- `lib/design_system` continua sendo o dono de tema, tokens e componentes
  maduros;
- `lib/core/design_system/components` é o catálogo modular solicitado no M03;
- componentes existentes são reexportados, nunca duplicados;
- APIs ausentes são implementadas no módulo correspondente;
- `fit_design_system.dart` continua sendo o import público recomendado.

Essa composição evita duas implementações concorrentes do mesmo Design System.

Os nomes `AppColors`, `AppSpacing` e `AppMotion` permanecem como aliases
legados. A implementação usa as fontes oficiais do M02: `FitColors`,
`FitTypography`, `FitSpacing`, `FitRadius`, `FitDuration` e `ThemeData`.
Nenhum `AppTypography` ou `AppRadius` paralelo foi criado.

## Catálogo entregue

| Módulo | APIs solicitadas | Novas classes | Reutilizadas |
| --- | ---: | ---: | ---: |
| Buttons | 8 | 7 | 1 |
| Inputs | 14 | 10 | 4 |
| Cards | 9 | 6 | 3 |
| Navigation | 7 | 5 | 2 |
| Feedback | 9 | 4 | 5 |
| Common | 10 | 7 | 3 |
| **Total** | **57** | **39** | **18** |

## Componentes novos

### Buttons

- `FitPrimaryButton`;
- `FitSecondaryButton`;
- `FitOutlinedButton`;
- `FitGhostButton`;
- `FitDangerButton`;
- `FitFAB`;
- `FitLoadingButton`.

### Inputs

- `FitEmailField`;
- `FitDropdown`;
- `FitDatePickerField`;
- `FitTimePickerField`;
- `FitSlider`;
- `FitStepper`;
- `FitCheckbox`;
- `FitSwitch`;
- `FitRadio`;
- `FitOTPField`.

### Cards

- `FitElevatedCard`;
- `FitOutlinedCard`;
- `FitSectionCard`;
- `FitInfoCard`;
- `FitEmptyStateCard`;
- `FitLoadingCard`.

### Navigation

- `FitTopBar`;
- `FitSearchBar`;
- `FitFABContainer`;
- `FitBottomSheetContainer`;
- `FitDialogContainer`.

### Feedback

- `FitSnackBar`;
- `FitCircularLoading`;
- `FitLinearLoading`;
- `FitWarningState`.

### Common

- `FitAvatar`;
- `FitProgressRing`;
- `FitTag`;
- `FitSectionTitle`;
- `FitListTile`;
- `FitStatistic`;
- `FitLabel`.

## Componentes reutilizados

- Buttons: `FitIconButton`;
- Inputs: `FitTextField`, `FitSearchField`, `FitPasswordField`,
  `FitNumberField`;
- Cards: `FitCard`, `FitMetricCard`, `FitProgressCard`;
- Navigation: `FitBottomNavigation`, `FitSectionHeader`;
- Feedback: `FitLoading`, `FitEmptyState`, `FitErrorState`,
  `FitOfflineState`, `FitSuccessState`;
- Common: `FitChip`, `FitBadge`, `FitDivider`.

## Estrutura criada

```text
lib/core/design_system/components/
|- buttons/
|- inputs/
|- cards/
|- navigation/
|- feedback/
|- common/
`- components.dart

lib/debug/design_system_showcase/
|- main.dart
|- showcase_app.dart
|- showcase_home_page.dart
|- showcase_section.dart
`- pages/

test/design_system/
`- component_library_m03_test.dart

docs/design_system/
|- COMPONENT_LIBRARY.md
`- DS3_M03_COMPONENTS_REPORT.md
```

Foram criados 44 arquivos:

- 31 arquivos no catálogo modular;
- 10 arquivos no showcase isolado;
- 1 arquivo de testes;
- 2 documentos.

Foram modificados 26 arquivos existentes, todos restritos ao Design System:
barrel público, tokens e componentes maduros reutilizados. `pubspec.yaml`,
`main.dart`, telas, providers, services e repositories permaneceram intactos.

## Tokens e componentes ajustados

Componentes maduros reutilizados receberam somente centralização de valores
visuais já existentes. Foram incluídos papéis em `FitLayout`, `FitDuration` e
`FitIcons` para:

- alturas e tamanhos de botões;
- loading;
- ícones, badges e navegação;
- handles, dialogs e skeletons;
- opacidade de seleção e disabled;
- duração de SnackBar.

O ajuste responsivo de `FitOfflineState.compact` move a ação para uma linha
separada em celulares estreitos. Isso corrige overflow sem alterar seu contrato.

## Dependências

Nenhuma dependência foi adicionada. A implementação usa somente:

- Flutter SDK;
- Material;
- `ThemeData` e `ColorScheme`;
- tokens e componentes internos do FitIA.

## Showcase

O showcase possui entrypoint e rotas próprios. Ele não está registrado no app:

```bash
flutter run -t lib/debug/design_system_showcase/main.dart
```

Todos os 57 nomes públicos aparecem nas páginas de Buttons, Inputs, Cards,
Navigation, Feedback e Common.

## Testes

Cobertura adicionada:

- ação, loading e disabled dos botões;
- estado controlado de input e stepper;
- SnackBar, bottom sheet e dialog;
- renderização das seis páginas do showcase;
- largura estreita de `320 px` sem overflow.

Comandos finais obrigatórios:

```bash
dart format .
flutter analyze
flutter test
```

Os resultados finais são registrados na seção **Validação final** após a
execução integral.

## Pendências

- golden tests não fazem parte do escopo e permanecem recomendados para uma
  etapa de regressão visual;
- componentes específicos de treino, nutrição e perfil permanecem fora desta
  biblioteca genérica, conforme solicitado;
- integração do showcase à navegação principal não foi realizada por desenho;
- tokens provisórios continuam sujeitos à validação visual do Design System
  3.0, preservando seus nomes semânticos.

## Recomendação para M04

Dedicar o M04 a componentes de domínio, iniciando apenas após definir quais
composições se repetem nas telas oficiais. O processo recomendado é:

1. inventário por módulo;
2. comparação visual com Official UI;
3. composição sobre esta biblioteca;
4. golden tests para estados críticos;
5. migração incremental sem alterar regras de negócio.

Esta recomendação não inicia o M04.

## Validação final

Executada em `D:\FitIA\app`:

| Comando | Resultado |
| --- | --- |
| `dart format .` | 447 arquivos verificados; 0 alterações pendentes |
| `flutter analyze` | concluído sem erros, warnings ou infos |
| `flutter test` | 115 testes aprovados |
| `flutter test test/design_system/component_library_m03_test.dart` | 4 testes aprovados |

Também foi confirmado:

- 57 de 57 componentes solicitados encontrados no catálogo;
- nenhuma dependência adicionada;
- nenhum import circular detectado;
- nenhuma integração com o app principal;
- nenhum overflow nas seis páginas do showcase em `320 x 800`;
- nenhum arquivo de backend alterado.
