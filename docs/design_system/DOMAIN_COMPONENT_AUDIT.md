# Auditoria dos Componentes de Domínio

## Escopo

Auditoria realizada em 24 de julho de 2026 para o marco
`DS3.0-M04 — Componentes de Domínio do FitIA`.

Foram analisados:

- documentação dos módulos em `designs/design-system`;
- amostra transversal da Official UI;
- Core Components do M03;
- componentes `Fit*` existentes;
- widgets locais de Home, Planos, Treino, Atividades, Corridas, Passos,
  Biblioteca e Perfil;
- barrels públicos e dependências do projeto Flutter.

Nenhuma tela, provider, service, repository, rota ou dependência foi alterada.

## Resultado executivo

| Verificação | Resultado |
| --- | --- |
| Componentes solicitados | 149 |
| Componentes novos | 143 |
| Componentes reutilizados | 6 |
| Ausências no inventário nominal | 0 |
| Declarações públicas duplicadas | 0 |
| Domínios com barrel próprio | 11 |
| Barrel global de domínio | Presente |
| Imports de services/providers/repositories | 0 |
| Imports de sensores, câmera ou IO | 0 |
| Dependências adicionadas | 0 |
| Telas removidas ou migradas | 0 |

## Componentes reutilizados

As APIs abaixo já existiam e foram reexportadas no domínio correspondente:

- `FitQuickActionCard`;
- `FitCoachInsightCard`;
- `FitPlanCard`;
- `FitActivityCard`;
- `FitExerciseCard`;
- `FitProfileHeader`.

Não foram criadas versões paralelas.

## Fronteiras

### Confirmado

- componentes recebem dados prontos e callbacks;
- timer de descanso não instancia `Timer`;
- mapa e mídia recebem `child`;
- scanners são placeholders;
- compra, cupom e restauração são callbacks;
- permissões, integrações e backup são estados externos;
- modelos de apresentação são imutáveis;
- `fit_design_system.dart` continua sendo o import público recomendado.

### Fora do escopo

- cálculo de macros, calorias, pace ou XP;
- persistência;
- navegação real;
- GPS, mapa e sensores;
- câmera e scanner;
- pagamentos e lojas;
- autenticação e sincronização;
- substituição dos widgets de tela atuais.

## Tokens

Foram adicionados papéis dimensionais provisórios a `FitLayout` para mídia,
mapa, gráficos, avatares, métricas, atalhos e progress rings de domínio.
Componentes legados reutilizados tiveram altura, avatar, opacidade e limites de
conteúdo centralizados sem alterar a API.

Valores matemáticos de domínio, como progresso entre `0` e `1`, não são tokens
visuais.

## Responsividade e acessibilidade

- composições de métricas usam `Wrap`;
- cards e linhas aceitam texto longo com limites explícitos;
- ações somente com ícone usam tooltip;
- status combinam cor, texto e ícone;
- controles declaram estado habilitado, selecionado ou pausado em Semantics;
- `FitSettingsNavigationTile` foi ajustado após teste em `320 px` com texto a
  `200%`, movendo o valor para o conteúdo textual e preservando a seta.

## Validação automatizada

`test/design_system/domain_components_m04_test.dart` verifica:

- os 12 componentes representativos obrigatórios;
- callbacks;
- loading e disabled;
- tema escuro;
- Semantics;
- texto longo e text scaling;
- barrels;
- ausência de imports proibidos.

Resultado integral:

- `dart format .`: 490 arquivos verificados;
- `flutter analyze`: sem issues;
- `flutter test`: 123 testes aprovados.

## Riscos restantes

- golden tests ainda não existem;
- os tokens dimensionais de domínio permanecem provisórios até medição visual
  controlada;
- componentes não foram integrados às telas, portanto equivalência visual de
  fluxos completos ainda não foi avaliada;
- estados hover/focus em web precisam de validação manual;
- dados reais podem revelar composições que exigem novas variantes, não novas
  responsabilidades.
