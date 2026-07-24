# DS3.0-M02 — Flutter Foundations Mapping

## Status

Concluído em 2026-07-23.

Este marco transforma foundations documentadas do FitIA Design System 3.0 em
uma base Flutter reutilizável. O escopo ficou restrito a tokens, tema,
compatibilidade, documentação e testes. Nenhuma tela, regra de negócio,
navegação, integração ou API foi implementada ou alterada.

## Arquitetura adotada

O aplicativo já possuía `lib/design_system`. Essa árvore foi preservada como
implementação oficial, evitando uma segunda estrutura em
`lib/core/design_system`.

```text
lib/design_system/
|- fit_design_system.dart
|- tokens/
|  |- fit_colors.dart
|  |- fit_gradients.dart
|  |- fit_typography.dart
|  |- fit_number_styles.dart
|  |- fit_spacing.dart
|  |- fit_radius.dart
|  |- fit_layout.dart
|  |- fit_shadows.dart
|  |- fit_elevation.dart
|  |- fit_opacity.dart
|  |- fit_breakpoints.dart
|  |- fit_duration.dart
|  `- fit_states.dart
|- theme/
|  |- fit_theme.dart
|  `- fit_theme_extensions.dart
|- components/
`- extensions/
```

O import público continua sendo:

```dart
import 'package:fitai/design_system/fit_design_system.dart';
```

## Arquivos criados

- `lib/design_system/tokens/fit_layout.dart`;
- `lib/design_system/tokens/fit_number_styles.dart`;
- `lib/design_system/tokens/fit_states.dart`;
- `test/design_system/design_system_foundations_test.dart`;
- `docs/design_system/FLUTTER_MAPPING.md`;
- `docs/design_system/MIGRATION_NOTES.md`;
- `docs/design_system/LITERAL_VALUES_AUDIT.md`;
- `docs/design_system/DS3_M02_REPORT.md`.

## Arquivos modificados

- tokens existentes em `lib/design_system/tokens`;
- `lib/design_system/theme/fit_theme.dart`;
- `lib/design_system/theme/fit_theme_extensions.dart`;
- `lib/design_system/extensions/context_extensions.dart`;
- `lib/design_system/fit_design_system.dart`;
- `lib/design_system/README.md`;
- dois Core Components com literais locais;
- `lib/theme/app_theme.dart`;
- teste de componentes ajustado à separação semântica entre IA e informação.

A relação completa está no estado do Git do projeto `app`.

## Classes criadas

| Classe | Responsabilidade |
| --- | --- |
| `FitLayout` | dimensões estruturais e alvos de toque provisórios |
| `FitNumberStyles` | aliases numéricos para timer, pace, carga e progresso |
| `FitStateTokens` | regras e resolvers reutilizáveis de estados |
| `FitThemeGradients` | gradientes que não cabem em `ColorScheme` |

## Classes modificadas

| Classe | Mudança |
| --- | --- |
| `FitColors` | paleta privada e tokens semânticos DS3 |
| `FitGradients` | gradientes documentados e aliases legados centralizados |
| `FitTypography` | escala semântica e `TextTheme` completos |
| `FitSpacing` | escala, aliases de contexto e compatibilidade |
| `FitRadius` | papéis semânticos e `BorderRadius` reutilizáveis |
| `FitShadows` | camadas provisórias centralizadas |
| `FitElevation` | composição semântica de camadas e elevação Material |
| `FitOpacity` | estados de opacidade documentados |
| `FitBreakpoints` | breakpoints provisórios centralizados |
| `FitDuration` | durações e curvas de motion centralizadas |
| `FitSemanticColors` | cores de domínio, gráficos e superfícies adicionais |
| `FitTheme` | `ThemeData` escuro oficial |
| `AppTheme` | delegação oficial e configuração estrutural legada |

## Tokens implementados

- backgrounds, surfaces, cards, borders, divider e texto;
- primary e papéis por domínio: IA, informação, energia, warning, error, XP,
  Premium, corrida e passos;
- containers, overlay e estados de superfície;
- gradientes de ação, scrim, gráfico, IA, Premium e profundidade;
- display, heading, title, subtitle, body, label, caption, button, chip,
  navigation, metric, small metric e overline;
- timer, pace, carga, progresso, porcentagem, tabela e unidade;
- spacing, radius, layout, opacity, breakpoints, shadows, elevation, motion e
  states.

O status individual de cada token está em
[FLUTTER_MAPPING.md](./FLUTTER_MAPPING.md).

## ThemeExtensions

Foram usadas somente extensões que cobrem lacunas reais:

- `FitSemanticColors`: cores de domínio, gráficos e superfícies adicionais;
- `FitThemeGradients`: gradientes sem representação natural em
  `ColorScheme`.

As cores globais continuam em `ColorScheme`, e tipografia continua em
`TextTheme`.

## Compatibilidade

- `AppTheme.dark` delega para `FitTheme.dark()`;
- `AppTheme.legacyDark` preserva a estrutura anterior, com aliases atuais;
- `AppColors`, `AppSpacing`, `AppRadii` e `AppMotion` continuam válidos;
- `AppMotion` preserva exatamente os tempos legados de `160/240/320 ms`;
- aliases existentes de `FitColors` foram preservados;
- gradientes antigos permanecem centralizados como `legacy*`;
- o barrel existente continua sendo o único ponto público;
- nenhuma migração massiva de telas foi executada.

Detalhes e plano de retirada estão em
[MIGRATION_NOTES.md](./MIGRATION_NOTES.md).

## Testes adicionados

O teste de foundations cobre:

1. criação do tema escuro;
2. `ColorScheme` dark;
3. tokens críticos não transparentes;
4. estilos tipográficos e numéricos;
5. escala crescente de spacing;
6. radius não negativo;
7. durações positivas;
8. `ThemeExtension` disponíveis;
9. APIs exportadas pelo barrel;
10. aliases de compatibilidade;
11. padrões globais essenciais do `ThemeData`.

## Resultados

| Validação | Resultado |
| --- | --- |
| `dart format .` | 405 arquivos verificados, 0 alterados |
| `flutter analyze` | sem issues |
| `flutter test test/design_system` | 21 testes aprovados |
| `flutter test` | 111 testes aprovados |

Logs esperados de cenários offline aparecem durante a suíte, mas não causam
falhas.

### Integridade do workspace

- `pubspec.yaml` e `pubspec.lock` não foram alterados;
- nenhum arquivo foi removido;
- nenhum arquivo em `lib/screens` foi alterado;
- backend e Official UI permaneceram sem alterações;
- os quatro novos nomes públicos (`FitLayout`, `FitNumberStyles`,
  `FitStateTokens` e `FitThemeGradients`) possuem uma única declaração cada;
- 112 documentos Markdown verificados não estão vazios;
- nenhum link local quebrado foi encontrado nos documentos do Design System.

A auditoria global encontrou 13 grupos de nomes públicos repetidos em arquivos
legados não tocados pelo M02. Onze pertencem a implementações paralelas de Home,
Treino e Exercício; dois pertencem ao par condicional `health_steps_reader_io`
e `health_steps_reader_stub`. O Dart os mantém em bibliotecas separadas e o
analyze passa, mas a duplicação semântica não deve crescer. Nenhuma duplicação
nova foi introduzida por esta sprint.

## Auditoria de literais

A busca encontrou 1.924 ocorrências textuais:

- 90 permitidas;
- 1.823 legadas;
- 11 candidatas a token;
- 0 sem classificação após triagem.

Nenhuma migração massiva foi feita. O inventário completo está em
[LITERAL_VALUES_AUDIT.md](./LITERAL_VALUES_AUDIT.md).

## Valores provisórios

Continuam `PROVISÓRIO` ou `A VALIDAR`:

- valor cromático final do primary e dos acentos de domínio;
- alpha de disabled, overlay e containers;
- tamanhos, pesos e leading tipográficos;
- spacing, radius, breakpoints e dimensões de layout;
- sombras e elevação;
- durações e curvas de motion;
- stops e intensidade de gradientes;
- comportamento do futuro tema claro.

Nenhum desses valores deve ser tratado como contrato final somente por já
existir no Flutter.

## Pendências

- medir foundations em viewports controlados;
- validar contraste dos estados e acentos;
- comparar o tema em Android, iOS, Web e desktop;
- validar text scaling nos fluxos principais;
- migrar literais por módulo;
- validar Grid e Navigation antes de migrar side navigation;
- definir e licenciar uma família tipográfica, caso o produto deixe de usar o
  fallback da plataforma;
- remover aliases apenas após busca de usos e comparação visual.

## Riscos

- telas legadas ainda possuem alta concentração de valores locais;
- mudanças futuras em tokens provisórios podem produzir diferenças visuais;
- a configuração `legacyDark` aumenta temporariamente a superfície de manutenção;
- não existe especificação oficial de tema claro;
- PNGs estáticos não sustentam valores finais de motion.
- nomes públicos duplicados preexistentes devem ser normalizados apenas em uma
  refatoração própria, com validação de imports e conditional exports.

## Recomendação para DS3.0-M03

Executar uma validação controlada de Spacing, Grid, Elevation, Icons e Motion,
com medições por viewport e estados interativos. Depois, migrar um único módulo
piloto usando os tokens públicos e comparação visual automatizada.

A sprint `DS3.0-M03` não foi iniciada.
