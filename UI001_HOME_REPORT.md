# UI001 — Relatório da Home

## Status

**Concluído.** As 17 telas documentadas para a Home foram implementadas,
conectadas ao fluxo existente e cobertas por testes de widget, smoke,
navegação, responsividade e regressão visual.

## Telas entregues

- HOME-001 Dashboard Principal
- HOME-002 Visão Geral
- HOME-003 Treino de Hoje
- HOME-004 Planos Sugeridos
- HOME-005 Próximos Treinos
- HOME-006 Conquistas
- HOME-007 Calendário
- HOME-008 Progresso
- HOME-009 Atividade Recente
- HOME-010 Lembretes
- HOME-011 Metas
- HOME-012 Notificações
- HOME-013 Recordes
- HOME-014 Desafios da Semana
- HOME-015 Coach FitIA
- HOME-016 Resumo Diário
- HOME-017 Personalizar Dashboard

## Arquivos criados

### Páginas

- `lib/features/home/presentation/pages/home_calendar_page.dart`
- `lib/features/home/presentation/pages/home_customize_page.dart`
- `lib/features/home/presentation/pages/home_daily_summary_page.dart`
- `lib/features/home/presentation/pages/home_overview_page.dart`
- `lib/features/home/presentation/pages/home_page_detail_navigation.dart`
- `lib/features/home/presentation/pages/home_progress_page.dart`
- `lib/features/home/presentation/pages/home_recent_activity_page.dart`
- `lib/features/home/presentation/pages/home_records_page.dart`
- `lib/features/home/presentation/pages/home_reminders_page.dart`
- `lib/features/home/presentation/pages/home_suggested_plans_page.dart`
- `lib/features/home/presentation/pages/home_today_workout_page.dart`
- `lib/features/home/presentation/pages/home_upcoming_workouts_page.dart`
- `lib/features/home/presentation/pages/home_weekly_challenges_page.dart`

### Widgets e testes

- `lib/features/home/presentation/widgets/home_dashboard_cards.dart`
- `lib/features/home/presentation/widgets/home_official_components.dart`
- `test/home/home_official_pages_test.dart`
- `test/home/home_test_fixtures.dart`
- `test/home/home_visual_regression_test.dart`
- `test/home/goldens/home/HOME-001.png` até `HOME-017.png`
- `HOME_IMPLEMENTATION.md`
- `UI001_HOME_REPORT.md`

## Arquivos alterados

- controller e estado da Home;
- rotas e barrels do módulo;
- página principal e extensões de navegação;
- páginas existentes de Coach, Metas, Conquistas e Notificações;
- header, loading, conteúdo pronto, insight do Coach e conquista recente;
- tiles de conquista e notificação;
- testes existentes de dashboard e navegação.

O backend, serviços, providers, modelos, dependências, Official UI e
documentação do Design System não foram alterados.

## Componentes reutilizados

Foram reutilizados os componentes oficiais de cards, botões, top bar, badges,
chips, avatar, progresso, mídia, gráficos, skeletons e estados de feedback.
As novas composições permanecem locais à feature Home e não duplicam a
biblioteca global.

## Integrações preservadas

- treino em andamento e detalhe do plano;
- criação de plano;
- Corridas e Passos;
- Coach, metas, conquistas e notificações;
- agenda, histórico, recordes e armazenamento local;
- cache/offline e Developer Mode;
- atualização de XP e refresh após retorno de fluxos.

## Bugs encontrados e corrigidos

- O card de resumo podia causar `RenderFlex overflow` em 320 px com texto a
  150%; o cabeçalho agora quebra de linha e as ações inferiores se empilham.
- O teste de navegação do Coach tocava um título não interativo; agora valida o
  card acionável.
- O calendário recebeu data inicial injetável para tornar a regressão visual
  determinística.
- Valores visuais legados usados pela Home foram substituídos por tokens de
  breakpoint, espaçamento, dimensão e opacidade.

## Pendências honestas

- O chat conversacional completo do Coach depende de fluxo próprio já fora
  deste escopo.
- Lembretes e personalização do dashboard ainda não possuem persistência
  dedicada.
- Recompensas de desafios não possuem contrato de domínio próprio.
- Capas fotográficas específicas dos mockups dependem de assets licenciados;
  a implementação preserva a estrutura com mídia disponível ou fallback.

## Diferenças visuais restantes

- Conteúdo real varia em relação aos exemplos estáticos.
- A barra inferior segue o App Shell oficial atual.
- Alguns mockups usam fotografias sem equivalente no bundle.
- Tipografia acompanha a fonte disponível na plataforma por meio do
  `ThemeData`.

## Validação

- `dart format .`: 542 arquivos verificados, nenhuma alteração pendente.
- `flutter analyze`: concluído sem erros ou warnings.
- `flutter test`: 166 testes aprovados.
- `flutter run -d edge --web-port 43117`: app iniciado, Home carregada e
  navegação inferior validada.
- Testes de regressão: 17 goldens aprovados em 390 x 844.
- Responsividade: HOME-001 e HOME-002 validadas em 320 x 700 com texto a
  150%.

## Capturas comparativas

- Contato geral:
  `build/ui001_home_comparison/HOME_RUNTIME_COMPARISON_CONTACT_SHEET.png`
- Comparações individuais:
  `build/ui001_home_comparison/HOME-001_comparison.png`,
  `HOME-002_comparison.png`, `HOME-003_comparison.png`,
  `HOME-005_comparison.png` e `HOME-007_comparison.png`.
- Capturas de regressão das 17 telas:
  `test/home/goldens/home/`.

## Observação de runtime

O catálogo local contém referências antigas para
`assets/gifs/peito/supino_reto_com_barra.gif` e
`assets/gifs/pernas/agachamento_livre.gif`, ausentes no bundle atual. O
componente de mídia aplica fallback e a Home permanece funcional, mas o
mapeamento desses assets deve ser saneado no módulo proprietário dos dados de
exercício, fora do escopo desta sprint.
