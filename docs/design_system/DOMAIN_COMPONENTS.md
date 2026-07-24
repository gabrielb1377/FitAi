# Componentes de Domínio

## Objetivo

O catálogo de domínio traduz padrões recorrentes da Official UI em
composições Flutter reutilizáveis. Ele fica acima dos Core Components e abaixo
das telas. Seu papel é organizar conteúdo e interação visual sem conhecer
modelos de negócio, providers, serviços, rotas ou integrações de plataforma.

O import público recomendado permanece:

```dart
import 'package:fitai/design_system/fit_design_system.dart';
```

Imports modulares são permitidos quando reduzem o acoplamento:

```dart
import 'package:fitai/core/design_system/components/domain/workout/workout.dart';
```

## Arquitetura

```text
lib/core/design_system/components/domain/
|- shared/       # modelos de apresentação imutáveis
|- home/
|- plans/
|- workout/
|- activities/
|- running/
|- steps/
|- library/
|- nutrition/
|- profile/
|- premium/
|- settings/
`- domain.dart   # barrel público global
```

Cada domínio possui um barrel próprio. Componentes que já existiam no Design
System são reexportados, nunca redeclarados.

## Contrato

- Dados chegam formatados e prontos para apresentação.
- Estado é controlado pelo consumidor.
- Ações são expostas por callbacks nomeados.
- Timer, mídia, mapa, câmera, pagamento e sensores não são executados pelo
  componente.
- Cores, dimensões, espaçamentos, raios e opacidades usam tema e tokens `Fit*`.
- Texto ampliado pode quebrar ou reorganizar a composição sem perder conteúdo.
- Estado não depende apenas de cor; texto, ícone e Semantics acompanham o tom.
- Nenhum componente importa `services`, `providers` ou `repositories`.

## Modelos de apresentação

| Modelo | Responsabilidade |
| --- | --- |
| `FitMetricData` | Valor, unidade, ícone e contexto de uma métrica já formatada |
| `FitChartPoint` | Ponto simples para gráfico já agregado |
| `FitSeriesDisplayData` | Estado visual de uma série de musculação |
| `FitMacroDisplayData` | Valor e meta já definidos para um macronutriente |
| `FitAchievementDisplayData` | Conteúdo e progresso visual de uma conquista |
| `FitPlanWeekData` | Estado visual de uma semana do plano |
| `FitDomainTone` | Papel cromático semântico entre domínios |

Esses modelos não substituem entidades existentes do aplicativo. Eles são
imutáveis e limitados à fronteira de apresentação.

## Inventário

| Domínio | Solicitados | Novos | Reutilizados |
| --- | ---: | ---: | ---: |
| Home | 12 | 10 | 2 |
| Planos | 14 | 13 | 1 |
| Treino | 21 | 21 | 0 |
| Atividades | 11 | 10 | 1 |
| Corridas | 14 | 14 | 0 |
| Passos | 9 | 9 | 0 |
| Biblioteca | 15 | 14 | 1 |
| Nutrição | 19 | 19 | 0 |
| Perfil | 15 | 14 | 1 |
| Premium | 9 | 9 | 0 |
| Configurações | 10 | 10 | 0 |
| **Total** | **149** | **143** | **6** |

### Home

`FitGreetingHeader`, `FitDailySummaryCard`, `FitTodayWorkoutCard`,
`FitQuickStatsRow`, `FitQuickActionCard`, `FitCoachInsightCard`,
`FitStreakCard`, `FitDailyGoalCard`, `FitRecentActivityCard`,
`FitNotificationPreview`, `FitHomeSectionHeader` e
`FitDashboardCustomizerTile`.

### Planos

`FitPlanCard`, `FitPlanCompactCard`, `FitPlanHeader`, `FitPlanProgress`,
`FitPlanStatusBadge`, `FitPlanWeekSelector`, `FitWorkoutDayCard`,
`FitPlanExerciseRow`, `FitPlanCreationOptionCard`, `FitPlanSummaryCard`,
`FitPlanStatisticCard`, `FitPlanComparisonCard`, `FitPlanTemplateCard` e
`FitArchivedPlanCard`.

`FitPlanStatus` cobre `active`, `paused`, `completed`, `archived`, `public`,
`private`, `locked` e `loading`.

### Treino

`FitWorkoutHeader`, `FitWorkoutProgressHeader`, `FitExerciseMedia`,
`FitExerciseHeader`, `FitExerciseActionBar`, `FitSeriesCounter`,
`FitSeriesRow`, `FitRepsSelector`, `FitWeightSelector`,
`FitRestTimerWidget`, `FitExerciseRestScreenContent`,
`FitNextExerciseCard`, `FitWorkoutMiniPlayer`, `FitWorkoutCoachBubble`,
`FitExerciseHistoryPreview`, `FitExerciseProgressPreview`,
`FitWorkoutSummaryCard`, `FitWorkoutMetric`, `FitPersonalRecordBadge`,
`FitWorkoutXPCard` e `FitWorkoutCompletionHeader`.

`FitRestTimerWidget` recebe rótulo, progresso e callbacks. Ele não cria
`Timer`. `FitExerciseMedia` recebe o widget de mídia pronto.

### Atividades

`FitActivityCard`, `FitActivityCompactRow`, `FitActivityTypeChip`,
`FitActivityMetric`, `FitActivitySummaryCard`, `FitActivityCalendarDay`,
`FitActivityHistoryItem`, `FitActivityFilterBar`,
`FitWeeklyActivityChartCard`, `FitActivityRecordCard` e
`FitActivityEmptyState`.

`FitActivityType` cobre força, corrida, caminhada, ciclismo, cardio, passos e
atividade personalizada.

### Corridas

`FitRunningDashboardCard`, `FitRunMetric`, `FitRunLiveMetricGrid`,
`FitRunMapContainer`, `FitGPSStatus`, `FitRunControlBar`,
`FitRunPausePanel`, `FitRunSummaryCard`, `FitPaceChartCard`,
`FitHeartRateZoneCard`, `FitSplitRow`, `FitRouteCard`,
`FitIntervalStepCard` e `FitPersonalRunRecordCard`.

GPS, mapa e cronômetro são observados por estado externo. Nenhum sensor é
consultado pela biblioteca.

### Passos

`FitStepsProgressRing`, `FitStepsSummaryCard`, `FitStepsMetricRow`,
`FitStepsGoalCard`, `FitStepsWeeklyChartCard`, `FitStepsStreakCard`,
`FitStepsHistoryRow`, `FitStepsRankingCard` e `FitStepsAchievementCard`.

### Biblioteca

`FitExerciseCard`, `FitExerciseCompactRow`, `FitExerciseGridCard`,
`FitExerciseCategoryCard`, `FitMuscleGroupCard`, `FitEquipmentCard`,
`FitExerciseFilterChip`, `FitExerciseSearchResult`,
`FitExerciseFavoriteButton`, `FitExerciseDifficultyBadge`,
`FitMuscleViewerContainer`, `FitExerciseInstructionStep`,
`FitExerciseMistakeCard`, `FitExerciseAlternativeCard` e
`FitExerciseCollectionCard`.

O visualizador muscular é somente um container; a implementação anatômica é
fornecida pelo consumidor.

### Nutrição

`FitNutritionSummaryCard`, `FitCaloriesProgressRing`, `FitMacroRing`,
`FitMacroSummaryRow`, `FitMealCard`, `FitFoodCard`, `FitFoodCompactRow`,
`FitRecipeCard`, `FitWaterTrackerCard`, `FitWaterQuickAddButton`,
`FitDailyNutritionCard`, `FitNutritionScoreBadge`, `FitFastingTimerCard`,
`FitShoppingListItem`, `FitNutritionInsightCard`, `FitNutritionGoalCard`,
`FitMicronutrientRow`, `FitBarcodeScannerPlaceholder` e
`FitFoodPhotoScannerPlaceholder`.

Macros, calorias e metas chegam calculados. Os scanners são placeholders
visuais, sem câmera ou reconhecimento.

### Perfil

`FitProfileHeader`, `FitProfileAvatar`, `FitLevelBadge`,
`FitXPProgressCard`, `FitAchievementCard`, `FitAchievementBadge`,
`FitBodyMetricCard`, `FitWeightProgressCard`, `FitMeasurementRow`,
`FitProgressPhotoCard`, `FitPersonalRecordCard`,
`FitProfileStatisticCard`, `FitProfileMenuTile`,
`FitConnectedDeviceCard` e `FitPublicProfileHeader`.

### Premium

`FitPremiumHeroCard`, `FitPremiumBenefitTile`,
`FitPremiumComparisonRow`, `FitSubscriptionPlanCard`, `FitPremiumBadge`,
`FitFamilyMemberCard`, `FitPaymentHistoryRow`, `FitCouponField` e
`FitRestorePurchaseCard`.

Compra, restauração, cupom e assinatura são callbacks. Não existe integração
com loja ou pagamento nesta camada.

### Configurações

`FitSettingsSection`, `FitSettingsTile`, `FitSettingsSwitchTile`,
`FitSettingsNavigationTile`, `FitSettingsDangerTile`,
`FitSettingsAccountHeader`, `FitIntegrationTile`, `FitPermissionTile`,
`FitStorageUsageCard` e `FitBackupStatusCard`.

Permissões, integrações e backup são estados informados pela aplicação.

## Exemplo

```dart
FitRestTimerWidget(
  remainingLabel: formattedRemaining,
  progress: restProgress,
  paused: isPaused,
  onTogglePause: controller.toggleRest,
  onSkip: controller.skipRest,
  onAddTime: controller.addRestTime,
);
```

O widget não sabe como o tempo é calculado. Essa separação permite testar e
reutilizar a UI sem duplicar a regra de sessão.

## Estados

- `loading`: skeleton ou indicador local com geometria estável;
- `disabled`: callback removido, opacidade temática e Semantics atualizado;
- `empty`: ausência válida de dados, sem ser tratada como erro;
- `error`: apresentado pela tela ou por um Core Feedback Component;
- `offline`: responsabilidade da composição de tela, que mantém dados locais;
- `selected/current`: estado recebido, nunca inferido de singleton.

## Showcase

O entrypoint isolado contém uma página para cada domínio:

```bash
flutter run -t lib/debug/design_system_showcase/main.dart
```

Ele não está registrado na navegação principal.

## Testes

Os testes representativos estão em
`test/design_system/domain_components_m04_test.dart`. Eles cobrem renderização,
callbacks, loading, disabled, texto longo, escala de texto, tema escuro,
Semantics, barrels e fronteiras arquiteturais.

## Migração

Nenhum widget de tela foi removido nesta sprint. O plano incremental e as
equivalências estão em
[DOMAIN_COMPONENT_MIGRATION_MAP.md](./DOMAIN_COMPONENT_MIGRATION_MAP.md).

