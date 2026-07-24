# Mapa de Migração dos Componentes de Domínio

## Objetivo

Este mapa relaciona widgets locais encontrados nas telas com o catálogo
oficial M04. A sprint preserva todos os widgets atuais. A migração deve ocorrer
por tela, com comparação visual e teste de comportamento.

| Widget atual | Local atual | Componente oficial | Estratégia | Status |
| --- | --- | --- | --- | --- |
| `HomeGreetingHeader` | `lib/screens/home/widgets/home_greeting_header.dart` | `FitGreetingHeader` | Adaptar dados e ações; remover somente após comparação da Home | Mapeado |
| `HomeStatsRow` | `lib/screens/home/widgets/home_stats_row.dart` | `FitQuickStatsRow` | Converter estatísticas para `FitMetricData` | Mapeado |
| `TreinoDoDiaCard` | `lib/screens/home/widgets/treino_do_dia_card.dart` | `FitTodayWorkoutCard` | Preservar fluxo real e fornecer CTA por callback | Mapeado |
| `StreakCard` | `lib/screens/home/widgets/streak_card.dart` | `FitStreakCard` | Migrar valor e melhor sequência formatados | Mapeado |
| `HomeGoalProgress` | `lib/screens/home/widgets/home_goal_progress.dart` e `lib/features/home/presentation/widgets/home_goal_progress.dart` | `FitDailyGoalCard` | Consolidar consumidores em micro-sprint própria | Mapeado |
| `HomeNotificationBell` | `lib/screens/home/widgets/home_notification_bell.dart` | Core `FitIconButton` + `FitNotificationPreview` | Manter badge e navegação na tela | Mapeado |
| `PlanCard` | `lib/screens/treinos/widgets/plan_card.dart` | `FitPlanCard` / `FitPlanCompactCard` | Escolher variante pela densidade da lista | Mapeado |
| `ActivePlanSummary` | `lib/screens/treinos/widgets/plans/active_plan_summary.dart` | `FitPlanSummaryCard` | Manter decisões de plano fora do widget | Mapeado |
| `OfficialPlanCard` | `lib/screens/treinos/widgets/plans/official_plan_card.dart` | `FitPlanTemplateCard` | Adaptar tags e mídia | Mapeado |
| `UserPlanCard` | `lib/screens/treinos/widgets/plans/user_plan_card.dart` | `FitPlanCard` | Reutilizar implementação já existente | Mapeado |
| `PlanSummaryCard` | `lib/screens/treinos/widgets/plan_summary_card.dart` | `FitPlanSummaryCard` | Migrar métricas para DTO visual | Mapeado |
| `PlanWizardChoiceTile` | `lib/screens/treinos/widgets/plans/plan_wizard_choice_tile.dart` | `FitPlanCreationOptionCard` | Preservar estado do wizard no controller atual | Mapeado |
| `WorkoutHeader` | `lib/screens/treinos/widgets/workout_header.dart` e `lib/screens/treinos/widgets/workout/workout_header.dart` | `FitWorkoutHeader` | Consolidar duas implementações locais sem alterar sessão | Mapeado |
| `WorkoutSessionHeader` | `lib/screens/treinos/widgets/plans/workout_session_chrome.dart` | `FitWorkoutHeader` | Adaptar callbacks de fechar e menu | Mapeado |
| `WorkoutProgressHeader` | `lib/screens/treinos/widgets/plans/workout_session_chrome.dart` | `FitWorkoutProgressHeader` | Fornecer progresso calculado pelo fluxo atual | Mapeado |
| `WorkoutCurrentExercise` | `lib/screens/treinos/widgets/workout_current_exercise.dart` | `FitExerciseHeader` + `FitExerciseMedia` | Compor sem mover lógica de sessão | Mapeado |
| `ExerciseInputsRow` | `lib/screens/treinos/widgets/workout/exercise_inputs_row.dart` | `FitRepsSelector` + `FitWeightSelector` | Preservar controllers e validações atuais | Mapeado |
| `ExerciseHistoryCard` | `lib/screens/treinos/widgets/exercise_hub_widgets.dart` e `lib/screens/treinos/widgets/workout/exercise_history_card.dart` | `FitExerciseHistoryPreview` | Manter consulta de histórico na tela/service | Mapeado |
| `RestTimerWidget` | `lib/screens/treinos/widgets/rest_timer_widget.dart` | `FitRestTimerWidget` | O timer atual continua proprietário do tempo | Mapeado |
| `RestTimerCard` | `lib/screens/treinos/widgets/rest_timer_card.dart` e `lib/screens/treinos/widgets/workout/rest_timer_card.dart` | `FitRestTimerWidget` / `FitExerciseRestScreenContent` | Migrar apenas a apresentação | Mapeado |
| `ActivityCard` | `lib/screens/widgets/activities/activity_card.dart` | `FitActivityCard` | Reutilizar componente existente e mapear tipo | Mapeado |
| `ActivitiesSummary` | `lib/screens/widgets/activities/activities_summary.dart` | `FitActivitySummaryCard` | Converter métricas para DTO visual | Mapeado |
| `ActivityStatsGrid` | `lib/screens/widgets/activities/activity_stats_grid.dart` | `FitDomainMetricStrip` via cards públicos | Migrar por composição, sem expor primitive interno | Mapeado |
| `_CorridaCard` | `lib/screens/corridas/historico_corridas_page.dart` | `FitRunSummaryCard` / `FitRouteCard` | Migrar após validar histórico e mapa | Mapeado |
| `_RunMetric` | `lib/screens/corridas/historico_corridas_page.dart` | `FitRunMetric` | Adaptar para `FitMetricData` | Mapeado |
| `LibraryExerciseTile` | `lib/screens/exercicios/biblioteca/library_official_widgets.dart` | `FitExerciseCompactRow` | Preservar favoritos e navegação por callback | Mapeado |
| `LibraryExerciseMedia` | `lib/screens/exercicios/biblioteca/library_official_widgets.dart` | `FitExerciseMedia` | Fornecer GIF/placeholder existente como `child` | Mapeado |
| `ProfileHeader` | `lib/screens/perfil/widgets/profile/profile_header.dart` | `FitProfileHeader` | Reutilizar implementação oficial existente | Mapeado |
| `ProfileSummary` | `lib/screens/perfil/widgets/profile/profile_summary.dart` | `FitBodyMetricCard` / `FitProfileStatisticCard` | Migrar métricas gradualmente | Mapeado |
| `ProfileRecords` | `lib/screens/perfil/widgets/profile/profile_records.dart` | `FitPersonalRecordCard` | Manter origem dos recordes fora do componente | Mapeado |
| `ProfileSettings` | `lib/screens/perfil/widgets/profile/profile_settings.dart` | `FitSettingsSection` + `FitProfileMenuTile` | Preservar agrupamento e callbacks | Mapeado |
| `RecordeCard` | `lib/screens/perfil/widgets/recorde_card.dart` | `FitPersonalRecordCard` | Validar variações antes de remover legado | Mapeado |
| `RecordeMiniBadge` | `lib/screens/perfil/widgets/recorde_mini_badge.dart` | `FitAchievementBadge` / `FitPersonalRecordBadge` | Escolher pelo significado | Mapeado |

## Sem equivalente legado direto

Os componentes de Nutrição, Premium e parte de Configurações não possuem telas
ou widgets equivalentes implementados no aplicativo atual. Eles permanecem
disponíveis para composições futuras, sem integração de negócio nesta sprint.

## Regra de migração

1. Escolher uma única tela.
2. Registrar baseline visual e testes atuais.
3. Adaptar modelos de negócio para modelos de apresentação.
4. Substituir somente a composição visual.
5. Executar analyze e testes do módulo.
6. Comparar em celular pequeno, médio, tablet e web quando aplicável.
7. Remover o widget legado apenas quando não houver consumidores.

