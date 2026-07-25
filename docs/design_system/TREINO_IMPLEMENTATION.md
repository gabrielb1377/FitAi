# Treino Implementation

## Escopo

UI-003 implementa a experiencia de execucao de musculacao dentro do modulo
**Planos**. A sessao continua usando `TreinoEmAndamentoPage` como a unica
fonte de estado para series, carga, descanso, XP, historico, persistencia e
sincronizacao.

Nao foi criada uma aba nova na navegacao principal.

## Fluxo

```mermaid
flowchart TD
  A["Detalhe do plano"] --> B["WORK-001 Previa"]
  B --> C["WORK-002 Lista de exercicios"]
  B --> D["WORK-003 Exercicio ativo"]
  C --> D
  D --> E["WORK-021 Descanso inline entre series"]
  E --> D
  D --> F["WORK-006 Resumo do exercicio"]
  F --> G["WORK-004 Descanso entre exercicios"]
  G --> H["WORK-005 Proximo exercicio"]
  H --> D
  D --> I["WORK-007 Treino concluido"]
  I --> J["Historico existente"]
```

## Mapeamento das artes oficiais

| Arte | Estado | Implementacao |
| --- | --- | --- |
| WORK-001 | Implementado | `WorkoutPreviewPage` deriva metricas somente do plano. |
| WORK-002 | Preservado | `WorkoutDayPage` lista exercicios e abre detalhes. |
| WORK-003 | Atualizado | `OfficialWorkoutSession` prioriza midia, serie, carga, reps e atalhos. |
| WORK-004 | Implementado | etapa de descanso completa entre exercicios, usando o timer existente. |
| WORK-005 | Implementado | etapa de confirmacao do proximo exercicio. |
| WORK-006 | Implementado | resumo apos a ultima serie de um exercicio. |
| WORK-007 | Preservado | `TreinoFinalizadoPage` usa metricas reais da sessao. |
| WORK-008 | Preservado | resumo completo da finalizacao existente. |
| WORK-009 | Atualizado | historico abre bottom sheet com series reais. |
| WORK-010 | Preservado | progressao abre a superficie existente. |
| WORK-011 | Preservado | performance abre a superficie existente. |
| WORK-012 | Preservado | Coach usa o fluxo real e mostra fallback honesto. |
| WORK-013 | Preservado | XP abre a superficie existente. |
| WORK-014 | Preservado | troca mantem as series concluidas. |
| WORK-015 | Preservado | Biblioteca abre a ficha de execucao existente em bottom sheet. |
| WORK-016 | Preservado | notas usam o estado da sessao existente. |
| WORK-017 | Preservado | configuracoes usam o menu de edicao existente. |
| WORK-018 | Implementado | pausa congela o tempo visual sem criar outro timer. |
| WORK-019 | Preservado | encerrar confirma e salva o progresso real. |
| WORK-020 | Implementado | descarte exige confirmacao e nao grava historico. |
| WORK-021 | Implementado | descanso entre series e um widget inline no exercicio ativo. |
| WORK-022 | Preparado | `FitWorkoutMiniPlayer` existe no Design System; nao foi montado globalmente sem um gerenciador de sessao compartilhado. |

## Componentes

| Componente | Uso |
| --- | --- |
| `FitRestTimerWidget` | Possui modo `embedded` e tamanho de anel configuravel para descanso inline. |
| `FitExerciseRestScreenContent` | Descanso entre exercicios. |
| `FitNextExerciseCard` | Confirmacao do proximo exercicio. |
| `FitWorkoutCompletionHeader` | Resumo do exercicio e pausa. |
| `FitWorkoutSummaryCard` | Previa do treino. |
| `FitWorkoutCoachBubble` | Dica contextual antes do treino. |
| `FitBottomSheet` | Historico, Coach, progressao, performance, XP, biblioteca, notas e acoes adicionais. |

## Regras preservadas

- Um unico `Timer` controla o tempo da sessao e um unico `Timer` controla o descanso.
- O descanso entre series nao substitui a tela ativa.
- Apos a ultima serie, somente exercicios que ainda possuem sucessor passam pelo resumo e descanso completo.
- Pausar, encerrar e descartar sao acoes distintas.
- Dados reais permanecem prioritarios; nenhuma metrica de calorias, XP ou recorde foi inventada.
- A finalizacao existente continua salvando historico e mantendo a sincronizacao offline-first.

## Estados validados

- Sem exercicios: estado vazio existente.
- Sem historico: bottom sheet com estado explicito.
- Midia ausente: `ExercicioGifImage` mantem fallback existente.
- Coach indisponivel: fluxo real usa o fallback ja existente.
- Descanso pausado: timer nao avanca enquanto pausado.
- Tela estreita e texto ampliado: cabecalho, historico e acoes quebram para linhas seguras.

## Arquivos principais

- `lib/features/plans/workout_execution/pages/workout_preview_page.dart`
- `lib/features/plans/workout_execution/widgets/workout_execution_stages.dart`
- `lib/screens/treinos/treino_em_andamento_page.dart`
- `lib/screens/treinos/widgets/plans/official_workout_session.dart`
- `lib/screens/treinos/widgets/plans/workout_session_exercise_panel.dart`
- `lib/screens/treinos/widgets/plans/workout_session_chrome.dart`

## Pendencia consciente

O mini player nao deve ser exibido fora da pagina de treino enquanto nao existir
um estado compartilhado de sessao aprovado. Criar esse estado nesta sprint
duplicaria controle de timer, o que viola a arquitetura atual.
