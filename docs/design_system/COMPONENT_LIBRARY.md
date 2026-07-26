# FitIA Component Library

## Objetivo

A Component Library é a camada oficial de componentes reutilizáveis do FitIA.
Ela traduz tokens, `ThemeData` e padrões confirmados na Official UI em APIs
Flutter consistentes, acessíveis e independentes de regras de negócio.

Esta entrega não implementa telas do produto. Os componentes não conhecem
providers, services, repositories, rotas globais ou contratos de API.

## Import público

O import recomendado continua único:

```dart
import 'package:fitai/design_system/design_system.dart';
```

Imports modulares também estão disponíveis para consumidores muito isolados:

```dart
import 'package:fitai/core/design_system/components/buttons/buttons.dart';
```

## Arquitetura

```text
lib/
|- design_system/
|  |- design_system.dart          # API publica oficial
|  |- fit_design_system.dart      # compatibilidade
|  |- components/             # implementações maduras preservadas
|  |- theme/
|  `- tokens/
`- core/design_system/components/
   |- buttons/
   |- inputs/
   |- cards/
   |- navigation/
   |- feedback/
   |- common/
   `- components.dart
```

`lib/design_system` permanece responsável por tokens, tema e componentes já
estáveis. O catálogo modular em `lib/core/design_system/components` reexporta
essas implementações e adiciona somente APIs ausentes. Uma classe existente
nunca é copiada para obter outro caminho de importação.

### Nomenclatura de tokens

O M02 definiu `FitColors`, `FitTypography`, `FitSpacing`, `FitRadius` e
`FitDuration` como APIs oficiais. `AppColors`, `AppSpacing` e `AppMotion`
continuam aliases de compatibilidade em `lib/theme/app_theme.dart`;
`AppTypography` e `AppRadius` não existem no projeto.

Por isso, componentes novos consomem os tokens `Fit*` e `ThemeData`. Não foram
criados aliases paralelos apenas para satisfazer outro nome, pois isso
duplicaria a fonte de verdade.

## Contrato

Todo componente público deve:

- usar `ThemeData`, `ColorScheme` e tokens `Fit*`;
- receber estado e callbacks por parâmetros nomeados;
- ter construtor `const` quando o ciclo de vida permitir;
- declarar asserts para combinações inválidas;
- fornecer Semantics, tooltip ou label quando a ação não for autoexplicativa;
- respeitar o alvo mínimo de toque definido em `FitLayout`;
- adaptar texto e composição sem overflow;
- não acessar estado global nem executar regra de domínio.

Valores matemáticos, como progresso entre `0` e `1`, não são tokens visuais.
Dimensões, cores, opacidade, raio, duração e espaçamento sempre são tokens.

## Buttons

| Componente | Objetivo | Dependências e tokens | Casos de uso |
| --- | --- | --- | --- |
| `FitPrimaryButton` | Ação prioritária do contexto | `FitButton`, `ThemeData`, `FitLayout`, `FitSpacing`, `FitRadius` | salvar, avançar, concluir |
| `FitSecondaryButton` | Alternativa relevante | mesmos tokens do botão base | ação paralela sem competir com o CTA |
| `FitOutlinedButton` | Ação disponível de menor ênfase | mesmos tokens do botão base | tentar novamente, abrir detalhe |
| `FitGhostButton` | Comando discreto sem superfície | mesmos tokens do botão base | cancelar, pular, ver mais |
| `FitDangerButton` | Ação destrutiva | `ColorScheme.error` e tokens do botão base | excluir, encerrar |
| `FitIconButton` | Ação reconhecível somente por ícone | `FitLayout`, `FitOpacity`, `FitRadius` | voltar, fechar, menu |
| `FitFAB` | Ação flutuante contextual | `FitLayout`, `FitColors`, `FitSpacing` | adicionar item em uma coleção |
| `FitLoadingButton` | CTA com loading controlado | `FitButton` e tokens do botão base | envio e processamento |

Todos suportam estado desabilitado. Botões textuais suportam ícone, largura
total e tamanhos `small`, `medium` e `large`. `FitIconButton` e `FitFAB`
exigem tooltip; feedback tátil é opcional.

```dart
FitPrimaryButton(
  label: 'Salvar plano',
  icon: FitIcons.check,
  fullWidth: true,
  loading: isSaving,
  onPressed: save,
);
```

## Inputs

| Componente | Objetivo | Dependências e tokens | Casos de uso |
| --- | --- | --- | --- |
| `FitTextField` | Entrada textual genérica | `InputDecorationTheme`, `FitRadius`, `FitLayout` | nome, notas |
| `FitSearchField` | Busca com clear, erro, loading e debounce | `FitIcons`, `FitDuration`, tema de input | listas e biblioteca |
| `FitPasswordField` | Senha com visibilidade alternável | `FitTextField`, autofill, `FitIcons` | login e cadastro |
| `FitEmailField` | E-mail com teclado e autofill corretos | `FitTextField`, `FitIcons.email` | autenticação e conta |
| `FitNumberField` | Número decimal | `FitTextField` e formatter do Flutter | peso, carga, medidas |
| `FitDropdown` | Escolha em conjunto fechado | `DropdownButtonFormField`, tema de input | nível, categoria |
| `FitDatePickerField` | Data controlada | date picker da plataforma, `FitRadius` | nascimento, período |
| `FitTimePickerField` | Horário controlado | time picker da plataforma, `FitRadius` | lembrete, agenda |
| `FitSlider` | Ajuste contínuo ou dividido | `SliderTheme`, `FitSpacing` | duração, intensidade |
| `FitStepper` | Ajuste numérico incremental | `FitIconButton`, `FitRadius`, `FitSpacing` | séries, dias |
| `FitCheckbox` | Seleção múltipla ou aceite | `CheckboxTheme` | termos, filtros múltiplos |
| `FitSwitch` | Preferência binária imediata | `SwitchTheme` | notificações, integração |
| `FitRadio` | Escolha única controlada | `RadioGroup`, `RadioListTile` | local, modo |
| `FitOTPField` | Código numérico de tamanho fixo | `FitTypography.metricSmall`, formatters | verificação |

```dart
FitEmailField(
  controller: emailController,
  errorText: emailError,
);
```

O chamador é dono de controllers e valores. Pickers não persistem dados e
controles não aplicam validações específicas do produto.

## Cards

| Componente | Objetivo | Dependências e tokens | Casos de uso |
| --- | --- | --- | --- |
| `FitCard` | Superfície genérica com slots | `FitRadius`, `FitElevation`, `FitSpacing` | agrupamento essencial |
| `FitElevatedCard` | Superfície com elevação sutil | `FitCard`, `FitElevation.level1` | destaque contextual |
| `FitOutlinedCard` | Superfície delimitada | `FitCard`, `ColorScheme.outlineVariant` | grupos de baixa elevação |
| `FitSectionCard` | Seção com título e ação | `FitCard` | blocos resumidos |
| `FitMetricCard` | Métrica que exige superfície própria | `FitMetric`, `FitCard` | grids de indicadores |
| `FitProgressCard` | Progresso com contexto | `FitProgress`, `FitCard` | meta e evolução |
| `FitInfoCard` | Mensagem contextual curta | `FitColors`, `ThemeData`, `FitSpacing` | insight, aviso, sucesso |
| `FitEmptyStateCard` | Estado vazio dentro de superfície | `FitEmptyState`, `FitCard` | coleções enquadradas |
| `FitLoadingCard` | Skeleton com geometria estável | `FitSkeleton`, `FitCard` | carregamento de lista |

```dart
const FitProgressCard(
  title: 'Meta semanal',
  value: '68%',
  progress: .68,
  icon: FitIcons.progress,
);
```

Cards não devem ser aninhados por decoração. Use um card somente quando a
superfície comunica agrupamento, seleção ou interação.

## Navigation

| Componente | Objetivo | Dependências e tokens | Casos de uso |
| --- | --- | --- | --- |
| `FitTopBar` | App bar controlada pela tela | `ThemeData`, `FitLayout`, `FitIconButton` | título, voltar, ações |
| `FitBottomNavigation` | Navegação principal controlada | `FitDuration`, `FitLayout`, `FitElevation` | shell principal |
| `FitSectionHeader` | Cabeçalho de seção | `TextTheme`, `FitSpacing` | título e ver tudo |
| `FitSearchBar` | Busca em contexto de navegação | `FitSearchField` | toolbar e cabeçalho |
| `FitFABContainer` | Posicionamento seguro do FAB | `SafeArea`, `FitSpacing` | ação flutuante |
| `FitBottomSheetContainer` | Superfície de bottom sheet | `FitBottomSheet`, `FitRadius` | escolhas contextuais |
| `FitDialogContainer` | Superfície de dialog | `FitDialog`, `FitLayout` | confirmação curta |

```dart
Scaffold(
  appBar: FitTopBar(
    title: 'Planos',
    showBackButton: true,
    onBack: Navigator.of(context).pop,
  ),
);
```

Esses componentes não resolvem nomes de rota nem alteram a bottom navigation
do produto. O chamador controla índice, abertura, retorno e preservação de
estado.

## Feedback

| Componente | Objetivo | Dependências e tokens | Casos de uso |
| --- | --- | --- | --- |
| `FitSnackBar` | Feedback transitório | `ThemeData`, `FitDuration`, `FitRadius` | confirmação e erro curto |
| `FitLoading` | Loading inline ou de tela | `FitLayout`, `FitSpacing` | espera genérica |
| `FitCircularLoading` | Loading circular local | `FitLayout`, `ColorScheme` | botão, bloco |
| `FitLinearLoading` | Loading linear determinado ou não | `FitLayout`, `ColorScheme` | sincronização |
| `FitEmptyState` | Ausência válida de conteúdo | `FitButton`, `FitSpacing` | lista vazia |
| `FitErrorState` | Falha recuperável | `ColorScheme.error`, `FitButton` | erro sem cache |
| `FitOfflineState` | Conteúdo local ou ausência de rede | `FitBreakpoints`, `FitButton` | offline-first |
| `FitSuccessState` | Conclusão relevante | `ColorScheme.primary`, `FitButton` | fluxo concluído |
| `FitWarningState` | Atenção recuperável | `FitColors.warning`, `FitButton` | revisão necessária |

```dart
const FitSnackBar(
  message: 'Treino salvo.',
  tone: FitSnackBarTone.success,
).show(context);
```

Loading não deve substituir conteúdo local válido. Erro, offline e vazio são
estados diferentes e devem permanecer semanticamente distintos.

## Common

| Componente | Objetivo | Dependências e tokens | Casos de uso |
| --- | --- | --- | --- |
| `FitChip` | Filtro selecionável | `ThemeData`, `FitRadius`, `FitSpacing` | filtros e opções |
| `FitBadge` | Estado ou atributo curto | `FitOpacity`, `FitRadius`, `FitLayout` | IA, Premium, offline |
| `FitDivider` | Separação visual | `FitLayout`, `FitSpacing` | listas e grupos |
| `FitAvatar` | Identidade com fallback | `FitLayout`, `ColorScheme` | usuário e coach |
| `FitProgressRing` | Progresso circular | `FitCircularProgress`, `FitLayout` | meta e conclusão |
| `FitTag` | Metadado não interativo | `FitTagChip` | nível, categoria |
| `FitSectionTitle` | Alias semântico de seção | `FitSectionHeader` | blocos de conteúdo |
| `FitListTile` | Item de lista temático | `FitLayout`, `FitRadius`, `ThemeData` | ajustes e ações |
| `FitStatistic` | Estatística compacta | `FitMetric` | resumo sem card |
| `FitLabel` | Label com ícone opcional | `FitLayout`, `FitSpacing`, `TextTheme` | legendas e status |

```dart
const FitStatistic(
  label: 'Treinos',
  value: '12',
  icon: FitIcons.workout,
  trend: '+2 esta semana',
);
```

## Componentes de domínio

O M04 adiciona uma camada de composições específicas para Home, Planos,
Treino, Atividades, Corridas, Passos, Biblioteca, Nutrição, Perfil, Premium e
Configurações.

O catálogo possui 149 APIs: 143 classes novas e seis componentes existentes
reutilizados. Ele está documentado em
[DOMAIN_COMPONENTS.md](./DOMAIN_COMPONENTS.md), com migração incremental em
[DOMAIN_COMPONENT_MIGRATION_MAP.md](./DOMAIN_COMPONENT_MIGRATION_MAP.md) e
auditoria em [DOMAIN_COMPONENT_AUDIT.md](./DOMAIN_COMPONENT_AUDIT.md).

```dart
FitRunControlBar(
  active: session.isActive,
  paused: session.isPaused,
  onStart: controller.start,
  onTogglePause: controller.togglePause,
  onFinish: controller.requestFinish,
);
```

Componentes de domínio organizam apresentação. Eles não acessam sensores,
serviços, modelos persistentes ou rotas.

### Extensao de treino: UI-003

`FitRestTimerWidget` suporta `embedded: true` quando e exibido dentro de um
painel de exercicio que ja possui superficie visual. Nesse modo ele conserva
Semantics, progresso e callbacks externos, mas nao cria um segundo card.
`progressRingSize` permite adaptar o anel a superficies compactas sem introduzir
dimensoes locais. O componente continua sem timer proprio: a camada de sessao
fornece tempo, pausa e comandos.

`WorkoutExerciseHistoryPanel` e uma composicao de feature usada pela sessao de
treino. Ela recebe um `ExerciseHistorySnapshot` ja carregado, combina-o com as
series da sessao atual e oferece as visoes de series, carga e volume. O painel
nao acessa storage, rotas ou sincronizacao, mantendo a separacao entre
apresentacao e dados.

## Acessibilidade

- Tooltips são obrigatórios em ações somente com ícone.
- Botões e avatares interativos respeitam o alvo mínimo de toque.
- Loading, erro, sucesso, warning e offline usam live regions.
- Nenhum estado depende somente de cor; ícone, texto ou Semantics acompanha a
  cor semântica.
- Labels e valores dinâmicos devem ser objetivos e pronunciáveis.
- Texto ampliado pode quebrar linha; labels de navegação usam redução
  controlada apenas dentro de sua área estável.

## Responsividade

- Componentes não assumem largura de tela.
- A página consumidora escolhe `Wrap`, grid ou coluna conforme o contexto.
- `FitOfflineState.compact` desloca sua ação em celulares estreitos.
- Campos, botões full width e cards respeitam as constraints do pai.
- `FitBottomNavigation` mantém dimensões estáveis e destinos expansíveis.

## Showcase isolado

O catálogo executável está em:

```text
lib/debug/design_system_showcase/
```

Execute sem integrar ao app principal:

```bash
flutter run -t lib/debug/design_system_showcase/main.dart
```

As rotas locais cobrem Buttons, Inputs, Cards, Navigation, Feedback, Common e
os onze domínios do M04.

## Como criar um componente

1. Confirmar que a necessidade se repete e não é composição de APIs existentes.
2. Verificar Official UI e documentação do módulo DS3 correspondente.
3. Definir estado controlado e callbacks sem regra de domínio.
4. Usar somente tema e tokens oficiais para decisões visuais.
5. Adicionar documentação pública, asserts e Semantics.
6. Expor no barrel do módulo e no catálogo raiz.
7. Criar exemplo no showcase e teste de comportamento/responsividade.
8. Atualizar este documento e o relatório da sprint.

## Anti-padrões

- duplicar `FitCard`, `FitButton` ou outro componente por conveniência;
- importar provider, service ou repository na biblioteca;
- usar cores hexadecimais, padding, raio ou duração local;
- persistir estado do produto dentro do componente;
- esconder erro de layout com `FittedBox` indiscriminado;
- criar um componente específico de tela dentro da camada genérica;
- usar Snackbar, dialog ou bottom sheet sem contexto semântico.

## Validação

Os testes da biblioteca ficam em:

```text
test/design_system/component_library_m03_test.dart
test/design_system/domain_components_m04_test.dart
```

Eles validam interações essenciais, containers contextuais, componentes
representativos de todos os domínios e ausência de overflow no showcase em
largura de `320 px`.
