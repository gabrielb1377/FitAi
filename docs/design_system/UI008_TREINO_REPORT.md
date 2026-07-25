# UI-08 - Treino Oficial

## Resultado

O modulo Treino foi revisado contra as artes WORK-001 a WORK-022. A sprint
concentrou a implementacao em WORK-001 a WORK-012 e preservou os fluxos
existentes de pausa, encerramento, descarte, descanso inline, troca de exercicio
e persistencia.

Nenhum contrato de backend, modelo, provider, servico de sincronizacao, regra de
XP ou regra de progressao foi alterado.

## Divergencia de referencias

O texto da sprint cita `WORK-ALL-12` e nomeia WORK-001 a WORK-012 como
Aquecimento, Exercicio, Registro, Descanso, Timer, Historico, Troca, Conclusao,
Resumo, XP, Compartilhamento e Recuperacao. No estado atual do Design Repository
nao existe `WORK-ALL-12`; o README oficial registra 22 PNGs com outro
mapeamento, iniciando em Previa do Treino e terminando em Mini Player.

Por regra do projeto, os PNGs e o README presentes na pasta oficial prevaleceram.
Nenhuma tela sem contrato visual atual foi inventada.

## Telas validadas

| Tela | Resultado |
| --- | --- |
| WORK-001 | Previa com dados derivados do plano, resumo, destaques e Coach. |
| WORK-002 | Lista de exercicios preservada e integrada ao inicio da sessao. |
| WORK-003 | Execucao com midia principal, progresso, serie, carga, repeticoes, descanso e atalhos. |
| WORK-004 | Descanso entre exercicios usando o timer existente. |
| WORK-005 | Confirmacao do proximo exercicio. |
| WORK-006 | Resumo do exercicio concluido. |
| WORK-007 | Conclusao com metricas reais da sessao. |
| WORK-008 | Resumo completo preservado. |
| WORK-009 | Historico persistido e atual com filtros de serie, carga e volume. |
| WORK-010 | Progressao do exercicio no fluxo existente. |
| WORK-011 | Performance do exercicio no fluxo existente. |
| WORK-012 | Coach real quando disponivel e fallback honesto quando indisponivel. |

## Correcoes funcionais

### Historico do exercicio

A mensagem de historico vazio tinha uma causa objetiva: o bottom sheet lia
somente a lista `_historico` da sessao atual. Ele nao chamava
`ExerciseHistoryService`, apesar de o servico ja possuir a busca por ID, chave
semantica, nome normalizado e progresso legado.

A consulta agora carrega o snapshot persistido, filtra pelo exercicio atual e
adiciona as series ainda nao persistidas da sessao. O estado vazio so aparece
quando ambas as fontes estao vazias.

### Registro e troca de exercicio

- Toques duplicados em "Concluir serie" sao bloqueados durante a operacao.
- Carga e repeticoes em edicao sao restauradas ao voltar ao exercicio.
- Cada serie registra uma copia da identidade do exercicio que a originou.
- Trocar o exercicio nao reatribui series anteriores ao novo exercicio.

### Compartilhamento

O resumo de compartilhamento nao simula sucesso. Enquanto nao existe integracao
de compartilhamento, a interface mostra a previa nao sensivel e informa que a
acao esta indisponivel.

## Componentes reutilizados

- `FitButton`
- `FitBottomSheet`
- `FitFilterChip`
- `FitStatusChip`
- `FitEmptyState`
- `FitErrorState`
- `FitLoading`
- `FitRestTimerWidget`
- `FitExerciseRestScreenContent`
- `FitNextExerciseCard`
- `FitWorkoutCompletionHeader`
- `FitWorkoutSummaryCard`
- `FitWorkoutCoachBubble`
- `ExercicioGifImage`

## Componente novo

`WorkoutExerciseHistoryPanel` organiza o historico persistido e atual sem
acessar servicos diretamente. Ele oferece modos de serie, carga e volume,
incluindo loading, erro e vazio.

## Validacao visual

Foram geradas capturas reais da implementacao e comparacoes lado a lado:

- `artifacts/ui-08/actual/WORK-001.png` a `WORK-012.png`
- `artifacts/ui-08/comparisons/WORK-001-comparison.png` a
  `WORK-012-comparison.png`
- `artifacts/ui-08/comparisons/WORK-001-012-contact-sheet.png`

As comparacoes confirmam a estrutura e os fluxos principais. Nao e declarada
uma porcentagem artificial de fidelidade.

## Diferencas restantes

- WORK-001 e WORK-003 possuem altura maior em alguns viewports por causa dos
  dados dinamicos e da UX de execucao aprovada posteriormente.
- Fixtures sem GymVisual exibem o fallback de midia existente.
- WORK-008 ainda nao possui o grafico segmentado da arte oficial.
- WORK-010, WORK-011 e WORK-012 sao apresentados em bottom sheets para preservar
  o exercicio e a serie atuais.
- WORK-022 depende de um controlador compartilhado de sessao para funcionar fora
  da pagina sem criar timer duplicado.
- O mapeamento antigo de Aquecimento a Recuperacao precisa ser removido da
  solicitacao ou restaurado no Design Repository antes de uma implementacao
  visual fiel desses estados.

## Validacao executada

- `dart format .`: 553 arquivos verificados, nenhum arquivo reformatado.
- `flutter analyze`: concluido sem erros ou warnings.
- Testes direcionados de treino, historico e fluxo de planos: 28 testes
  aprovados.
- `flutter test`: 182 aprovacoes e uma falha; somente o golden preexistente
  `HOME-005 golden mobile` falhou, com diferenca de 1,41% (4.644 pixels).
- `flutter run -d web-server --web-port 0`: aplicacao compilada e servida; smoke
  HTTP retornou 200.

Os artefatos de falha do golden HOME-005 foram restaurados ao estado anterior.
Nenhum arquivo da Home foi alterado por esta sprint.

## Riscos

- A pagina legada de sessao concentra muitas responsabilidades e continua
  extensa; uma extracao futura deve preservar cuidadosamente os timers.
- Integrar o mini player antes de existir estado compartilhado pode criar duas
  fontes de tempo.
- A fidelidade da midia depende da disponibilidade dos arquivos GymVisual.

## Proxima micro-sprint recomendada

Extrair um controlador compartilhado e testavel para a sessao ativa, sem mudar
modelos ou persistencia. Isso desbloqueia WORK-022 e reduz o risco de rebuilds e
timers duplicados.
