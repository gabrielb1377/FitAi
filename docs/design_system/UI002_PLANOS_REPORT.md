# UI002: Relatorio do Modulo Planos

## Resultado

O App Shell agora abre a nova raiz oficial de Planos. A navegacao principal permanece com `Home`, `Planos`, `Atividades`, `Biblioteca` e `Perfil`; as pilhas das outras secoes nao foram alteradas.

## Arquivos criados

- `lib/features/plans/presentation/pages/planos_official_root_page.dart`
- `lib/features/plans/presentation/pages/planos_official_wizards.dart`
- `lib/features/plans/presentation/pages/planos_official_plan_pages.dart`
- `lib/features/plans/presentation/pages/planos_official_library_page.dart`
- `lib/features/plans/presentation/widgets/planos_official_primitives.dart`
- `test/planos_official_module_test.dart`
- `docs/design_system/PLANOS_IMPLEMENTATION.md`
- `docs/design_system/UI002_PLANOS_REPORT.md`

## Arquivos alterados

- `lib/features/plans/presentation/pages/plans_root_page.dart`
- `lib/features/plans/presentation/routes/plans_routes.dart`
- `lib/core/navigation/main_scaffold.dart`

## Componentes reutilizados

`FitHeader`, `FitPrimaryButton`, `FitOutlinedButton`, `FitLoadingButton`, `FitCard`, `FitPlanCard`, `FitPlanStatusBadge`, `FitMetricCard`, `FitProgress`, `FitCircularProgress`, `FitChip`, `FitTag`, `FitInfoCard`, `FitEmptyState`, `FitErrorState`, `FitSkeleton` e os tokens `FitColors`, `FitSpacing`, `FitRadius`, `FitLayout`, `FitIcons`, `FitGradients`.

## Componentes novos

Os seis primitivos `Planos*` documentados em `PLANOS_IMPLEMENTATION.md` foram criados dentro do modulo, pois sao composicoes repetidas exclusivamente pelas telas de Planos e nao duplicam um componente global existente.

## Funcionalidades preservadas

- dados locais e fallback offline de planos;
- criacao por IA via fluxo existente;
- criacao e edicao completa via editor existente;
- biblioteca pronta, favoritos, cache de detalhe e copia offline;
- inicio de treino pelo `WorkoutDayPage`;
- exclusao e duplicacao locais.

## Validacao executada

- `dart format .`: concluido sem alteracoes adicionais.
- `flutter analyze`: concluido sem issues.
- testes direcionados de Planos e goldens: concluido com sucesso.
- `flutter build web --debug`: concluido com sucesso.
- `flutter run`: a compilacao iniciou, mas o navegador integrado nao anexou ao servico de debug nesta maquina. A interface foi inspecionada a partir do build web debug estatico.
- `flutter test` integral: os testes de Planos passaram; a suite termina com uma falha preexistente/externa em `test/home/home_visual_regression_test.dart`, cujo golden `HOME-009` diverge 2,15% da baseline.

## Pendencias e riscos

- Arquivamento ainda nao pode ser persistido sem um campo de dominio dedicado. A tela nao grava um estado falso.
- Importacao externa nao possui integracao definida; o CTA informa isso de forma explicita.
- PLAN-018 e PLAN-019 continuam usando o conteudo interno legado para manter cache e sincronizacao. A moldura ja foi migrada, mas a fidelidade interna dessas duas telas deve ser tratada em `UI-002A`.
- A comparacao visual por screenshot deve registrar qualquer diferenca residual de espacamento e proporcao depois da execucao no navegador.

## Proximo micro-sprint recomendado

`UI-002A — Biblioteca de Planos Prontos`: migrar o conteudo de `ReadyPlansLibraryPage` e `ReadyPlanPreviewPage` para os componentes DS3 sem alterar o servico, o cache e a copia offline.
