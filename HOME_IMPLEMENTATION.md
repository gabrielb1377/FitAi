# Home Oficial

## Objetivo

Este documento registra a implementação Flutter do módulo Home a partir das
17 especificações visuais em
`D:\FitIA\designs\official-ui\02-Home`. A implementação preserva o App Shell,
as regras de negócio, o armazenamento local, o modo offline e as integrações
existentes.

## Referências

- `D:\FitIA\designs\official-ui\02-Home\README.md`
- `D:\FitIA\designs\official-ui\02-Home\HOME-001_Dashboard_Principal.png` até
  `HOME-017_Personalizar_Dashboard.png`
- `D:\FitIA\designs\design-system`
- Design System Flutter em `lib/design_system`
- App Shell e navegação em `lib/core/navigation`

## Telas implementadas

| Código | Página Flutter | Rota |
| --- | --- | --- |
| HOME-001 | `HomePage` / `HomeDashboardContent` | `/home` |
| HOME-002 | `HomeOverviewPage` | `/home/overview` |
| HOME-003 | `HomeTodayWorkoutPage` | `/home/today-workout` |
| HOME-004 | `HomeSuggestedPlansPage` | `/home/suggested-plans` |
| HOME-005 | `HomeUpcomingWorkoutsPage` | `/home/upcoming-workouts` |
| HOME-006 | `HomeAchievementsPage` | `/home/achievements` |
| HOME-007 | `HomeCalendarPage` | `/home/calendar` |
| HOME-008 | `HomeProgressPage` | `/home/progress` |
| HOME-009 | `HomeRecentActivityPage` | `/home/recent-activity` |
| HOME-010 | `HomeRemindersPage` | `/home/reminders` |
| HOME-011 | `HomeGoalsPage` | `/home/goals` |
| HOME-012 | `HomeNotificationsPage` | `/home/notifications` |
| HOME-013 | `HomeRecordsPage` | `/home/records` |
| HOME-014 | `HomeWeeklyChallengesPage` | `/home/weekly-challenges` |
| HOME-015 | `HomeCoachPage` | `/home/coach` |
| HOME-016 | `HomeDailySummaryPage` | `/home/daily-summary` |
| HOME-017 | `HomeCustomizePage` | `/home/customize` |

As telas secundárias são abertas no navegador da seção Home. O App Shell
continua responsável pela barra oficial
`Home | Planos | Atividades | Biblioteca | Perfil`.

## Dados e integrações

`HomeController` agrega somente fontes já existentes:

- treinos e histórico pelo `StorageService` e `TreinoService`;
- treino do dia pelo `TreinoDoDiaService`;
- Coach pelo `CoachInsightService` e `IaEvolutivaService`;
- metas pelo `MetasService`;
- conquistas pelo `AchievementService`;
- notificações pelo `NotificationService`;
- conectividade pelo `NetworkService`;
- sequência e XP semanal pelo `StreakService`;
- agenda pelo `AgendaTreinosService`;
- recordes pelos serviços locais já existentes.

Fixtures são utilizadas somente quando o Developer Mode autoriza e não
substituem dados reais. Lembretes, recompensas de desafios e personalização sem
persistência exibem estados honestos ou demonstrações protegidas pelo modo de
desenvolvimento.

## Componentes reutilizados

- `FitTopBar`, `FitCard`, `FitSection`, `FitSectionHeader`
- `FitPrimaryButton`, `FitOutlinedButton`, `FitIconButton`
- `FitBadge`, `FitTag`, `FitFilterChip`, `FitAvatar`, `FitDivider`
- `FitProgressBar`, `FitCircularProgress`
- `FitSkeleton`, `FitListSkeleton`, `FitLinearLoading`
- `FitEmptyState`, `FitErrorState`, `FitOfflineState`
- `FitActionTile`, `FitCoachInsightCard`
- `FitDomainMedia`, `FitDomainBarChart`
- `FitSnackBar`

Todos os novos layouts usam `FitColors`, `FitSpacing`, `FitRadius`,
`FitOpacity`, `FitLayout`, `FitBreakpoints`, `FitDuration`, `FitIcons` e o
`TextTheme` ativo.

## Composições da Home

Foram criadas composições específicas do domínio, sem duplicar componentes
globais:

- `HomeXpCard`
- `HomeDailyMetrics`
- `HomeTodayCards`
- `HomePageBody`
- `HomeFilterStrip`
- `HomeMetricGrid` e `HomeMetricTile`
- `HomeChartCard`
- `HomeListAction`
- `HomeDetailScaffold`

Esses widgets ficam dentro de `features/home` porque organizam dados e
interações exclusivos do módulo.

## Estados

- **Loading:** skeletons preservam a hierarquia do dashboard.
- **Sucesso:** conteúdo real ou cache local.
- **Offline com cache:** banner discreto, dados locais e tentativa manual.
- **Erro sem cache:** `FitErrorState`, sem apagar dados.
- **Vazio:** estado específico em treino, planos, atividades, metas,
  conquistas, notificações e recordes.
- **Atualização:** indicador linear sem bloquear o conteúdo disponível.

## Responsividade e acessibilidade

- Layout mobile-first com breakpoints oficiais.
- Métricas e ações mudam de colunas para uma coluna em larguras estreitas.
- Conteúdo possui scroll, Safe Area e limites de largura do App Shell.
- Textos longos usam quebra, limites ou elipse conforme o contexto.
- Ações possuem Semantics, tooltips e alvos de toque do Design System.
- O cenário de 320 px com escala de texto em 150% possui teste dedicado.

## Performance

- `const` aplicado onde os dados são imutáveis.
- Dashboard usa `CustomScrollView` e slivers.
- Listas extensíveis usam builders.
- `AnimatedSwitcher` limita a animação aos estados principais.
- `HomeController` evita carregamentos simultâneos e mantém cache visível
  durante refresh.

## Diferenças controladas

- Textos, números, datas, imagens e estados refletem dados reais e podem
  divergir do conteúdo estático dos mockups.
- O App Shell atual prevalece sobre variantes antigas da barra inferior
  presentes nas imagens.
- Quando não há imagem de capa, a proporção visual é preservada com mídia do
  exercício ou placeholder semântico.
- Chat completo do Coach, persistência de lembretes e persistência da ordem do
  dashboard não foram inventados; a UI comunica a indisponibilidade.

## Testes

- `test/home/home_controller_test.dart`
- `test/home/home_dashboard_test.dart`
- `test/home/home_navigation_test.dart`
- `test/home/home_official_pages_test.dart`
- `test/home/home_visual_regression_test.dart`
- `test/home/goldens/home/HOME-001.png` até `HOME-017.png`

Os goldens validam as 17 primeiras viewports em 390 x 844. O smoke test abre
todas as páginas, e o teste responsivo cobre largura reduzida com texto
ampliado.
