# Literal Values Audit

## Objetivo

Inventariar valores visuais e temporais literais em `lib/` sem executar uma
migração massiva. A auditoria é textual e serve para priorização; não substitui
análise semântica do código.

Data da auditoria: 2026-07-23.

## Padrões pesquisados

- `Color(0x...)`;
- `Colors.*`;
- `TextStyle(...)`;
- `BorderRadius.circular` com número local;
- `EdgeInsets` com número local;
- `Duration` com número local.

## Resultado bruto

| Padrão | Ocorrências |
| --- | ---: |
| `Color(0x...)` | 279 |
| `Colors.*` | 566 |
| `TextStyle(...)` | 459 |
| `BorderRadius.circular(...)` numérico | 255 |
| `EdgeInsets...` numérico | 308 |
| `Duration(...)` numérico | 57 |
| **Total** | **1.924** |

Os números contam correspondências textuais, inclusive valores centralizados e
constantes de framework deliberadas.

## Classificação após triagem

| Classificação | Ocorrências | Tratamento |
| --- | ---: | --- |
| permitido | 90 | tokens centrais, `Colors.transparent`, timers de domínio e UI de debug |
| legado | 1.823 | preservar nesta sprint e migrar por módulo |
| candidato a token | 11 | navegação lateral em `core/` |
| precisa de revisão | 0 | nenhuma ocorrência permaneceu sem classificação |

### Permitido

- 73 ocorrências dentro de `design_system/tokens` e
  `design_system/theme`;
- 4 usos de `Colors.transparent` em componentes do Design System;
- 8 `Duration` de timeout, sincronização, GPS e regras temporais de serviço;
- 1 `Colors.transparent` em configuração de system UI;
- 4 valores exclusivos do banner de Developer Mode.

Tempos de rede, sincronização e sessão não são tokens de motion.

### Legado

As 1.823 ocorrências estão principalmente em telas e widgets anteriores ao
DS3. Elas não foram alteradas para evitar uma migração visual sem comparação
oficial.

Arquivos com maior concentração:

| Arquivo | Ocorrências |
| --- | ---: |
| `screens/treinos/treino_em_andamento_page.dart` | 397 |
| `screens/treinos/treino_profissional_page.dart` | 138 |
| `theme/app_theme.dart` | 73 |
| `screens/perfil/widgets/evolucao_dashboard_widgets.dart` | 49 |
| `screens/perfil/widgets/agenda_treinos_widgets.dart` | 49 |
| `screens/treinos/widgets/plan_card.dart` | 47 |
| `screens/exercicios/exercicio_detalhe_page.dart` | 43 |
| `screens/treinos/widgets/exercise_hub_widgets.dart` | 42 |
| `screens/perfil/calendario_treinos_page.dart` | 40 |
| `screens/treinos/historico_treinos_page.dart` | 39 |
| `screens/treinos/widgets/rest_timer_widget.dart` | 39 |
| `screens/treinos/criar_treino_page.dart` | 38 |

`theme/app_theme.dart` inclui a configuração estrutural `legacyDark` e widgets
legados. Esses valores estão preservados deliberadamente.

### Candidato a token

`core/navigation/side_navigation.dart` concentra 11 ocorrências visuais. A
navegação lateral deve ser migrada junto com a validação responsiva de Grid e
Navigation, não isoladamente.

### Core Components

Os números locais encontrados em `FitTextField` e `FitOfflineState` foram
substituídos por `FitSpacing` e `FitRadius`. Os quatro literais remanescentes
nos componentes são `Colors.transparent`, tratados como ausência explícita de
preenchimento e não como uma cor de marca.

## Priorização recomendada

1. validar Grid e Navigation antes de migrar `side_navigation.dart`;
2. migrar treino em andamento somente com comparação visual oficial;
3. separar a configuração `legacyDark` dos widgets legados em sprint própria;
4. migrar telas por módulo, com analyze, testes e screenshot;
5. não converter durações de serviço em motion;
6. manter cores de assets e dados fisiológicos semanticamente contextualizadas.

Nenhuma ocorrência legada foi corrigida automaticamente nesta auditoria.
