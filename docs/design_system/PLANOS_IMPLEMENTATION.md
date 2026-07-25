# Planos: Implementacao Oficial

## Escopo

O modulo Planos foi migrado para a raiz oficial do App Shell em `PlansRootPage`. A implementacao preserva o armazenamento local de `TreinoService`, o cache offline da Biblioteca de Planos Prontos, o fluxo real de geracao por IA e as telas legadas de execucao de treino.

## Telas

| Arte oficial | Implementacao | Estado |
| --- | --- | --- |
| PLAN-001 | `PlanosOfficialRootPage` | Dashboard, vazio, erro, offline e loading. |
| PLAN-002 a PLAN-005 | `PlanosAiGoalPage`, `PlanosAiPersonalizationPage`, `PlanosAiGeneratingPage`, `PlanosAiReadyPage` | Wizard visual; a geracao real continua em `AIWorkoutPage`. |
| PLAN-006 a PLAN-011 | `PlanosManualGoalPage`, `PlanosStructurePage`, `PlanosBuildWorkoutsPage`, `PlanosEditWorkoutPage`, `PlanosReviewPage`, `PlanosCreatedPage` | Wizard visual; a persistencia manual continua em `OfficialPlanEditorPage`. |
| PLAN-013 a PLAN-017 | `PlanosPlanDetailPage`, `PlanosWeekPage`, `PlanosWorkoutDetailPage`, `PlanosEditPlanPage`, `PlanosStatisticsPage` | Plano salvo, semana, dia, edicao e progresso. |
| PLAN-018 e PLAN-019 | `PlanosReadyLibraryPage` e fluxo existente de `ReadyPlansLibraryPage` | Dados, cache, favoritos e copia offline preservados. |
| PLAN-020 a PLAN-025 | `PlanosImportSharePage`, `PlanosCalendarPage`, `PlanosComparePage`, `PlanosHistoryPage`, `PlanosDuplicatePage`, `PlanosArchivePage` | Fluxos de suporte e operacoes locais disponiveis. |

`PLAN-012` nao existe no repositório oficial atual e, por isso, nao recebeu uma implementacao artificial.

## Componentes

Os widgets especificos do dominio ficam em `features/plans/presentation/widgets/planos_official_primitives.dart`:

- `PlanosOfficialPage`: moldura mobile-first, safe areas, CTA inferior e largura maxima de tablet.
- `PlanosPlanMedia`: reserva a geometria da midia mesmo sem asset disponivel.
- `PlanosMetricRow`: metricas horizontais de plano.
- `PlanosChoiceTile`: opcoes selecionaveis dos wizards.
- `PlanosNavigationRow`: linhas de configuracao, exercicio e acao contextual.
- `PlanosLoadingState`: skeleton coerente com PLAN-001.

Eles sao compostos exclusivamente de tokens e componentes `Fit*`: `FitHeader`, `FitCard`, `FitButton`, `FitChip`, `FitPlanCard`, `FitProgress`, `FitEmptyState`, `FitErrorState` e `FitInfoCard`.

## Dados e compatibilidade

- A lista inicial usa `PlansController` e, portanto, continua offline-first.
- `MainScaffold` oculta a barra inferior enquanto uma rota interna da secao esta aberta; ela permanece nas cinco telas raiz. Isso reproduz os wizards e detalhes oficiais sem alterar a navegacao entre Home, Planos, Atividades, Biblioteca e Perfil.
- Nenhum modelo, provider, service, contrato de API ou backend foi alterado.
- A duplicacao cria uma copia persistida pelo `TreinoService`.
- A edicao exposta na nova tela persiste apenas o nome, que e o unico campo editavel nesta primeira camada visual; o editor legado continua disponivel para a edicao completa.
- A biblioteca de planos prontos continua usando `ReadyPlansService`, inclusive cache de lista e detalhe.

## Restricoes conhecidas

- O modelo atual de `TreinoModel` nao possui status de arquivamento. PLAN-025 deixa isso explicito e nao simula persistencia inexistente.
- Importacao por link ou arquivo ainda depende de uma fonte compativel no backend; PLAN-020 apresenta o estado honesto em vez de criar um contrato novo.
- O conteudo interno da biblioteca pronta e da geracao real ainda e fornecido pelas telas legadas, para preservar cache e integracao. A moldura e a entrada pelo App Shell ja seguem a composicao oficial; a migracao visual interna pode ser feita em micro-sprint proprio.

## Validacao

Os testes de widget em `test/planos_official_module_test.dart` cobrem:

- vazio e atalhos de PLAN-001;
- wizard IA PLAN-002 e PLAN-003;
- fluxo manual PLAN-006 a PLAN-010 em viewport estreito;
- detalhe e semana PLAN-013 e PLAN-014;
- estados explicitos de PLAN-020 e PLAN-025.

Os goldens em `test/planos_official_golden_test.dart` registram PLAN-001, PLAN-002 e PLAN-013 em viewport mobile. A execucao direcionada desses testes passa. A suite integral permanece com uma divergencia conhecida e fora deste escopo em `test/home/home_visual_regression_test.dart` (`HOME-009`, 2,15% de pixels), sem falhas nos testes de Planos.
