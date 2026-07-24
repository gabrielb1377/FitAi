# Navegação Oficial

## Arquitetura principal

A barra inferior possui exatamente cinco destinos, nesta ordem:

1. Home
2. Planos
3. Atividades
4. Biblioteca
5. Perfil

`AppShellSection` é a fonte única para ordem, label, path e ícones.

## Bottom Navigation

`ShellNavigation` compõe o componente oficial `FitBottomNavigation`.

- permanece inferior em Android, iOS, Web e tablet;
- respeita safe area;
- usa ícone e label em todos os destinos;
- mantém alvo de toque e Semantics do Design System;
- limita a largura em viewports grandes;
- não cria sidebar nem Navigation Rail sem nova decisão visual.

## NavigationController

O controller expõe:

| API | Uso |
| --- | --- |
| `currentSection` | Seção selecionada. |
| `selectSection` | Alternar por identificador tipado. |
| `selectIndex` | Compatibilidade temporária com callbacks antigos. |
| `navigatorKeyFor` | Chave estável da pilha de uma seção. |
| `pushNamed` | Abrir rota dentro da seção correta. |
| `maybePopCurrent` | Retornar dentro da pilha ativa. |
| `popToRoot` | Limpar apenas a pilha informada. |
| `openDeepLink` | Resolver e abrir um link já autorizado. |

Controllers de feature usam `SectionNavigationController`, evitando conhecer
índices ou chaves globais.

## Preservação de estado

O `IndexedStack` mantém os cinco `SectionNavigator` montados. Assim:

- scroll não é reiniciado ao trocar de aba;
- formulários e filtros locais permanecem;
- uma página interna de Planos continua aberta após visitar Biblioteca;
- serviços centrais de corrida e passos não são recriados;
- a Bottom Navigation não é recriada em páginas internas.

## Comportamento de voltar

1. Se a seção atual possui uma rota interna, voltar remove essa rota.
2. Se a seção está na raiz e não é Home, voltar seleciona Home.
3. Se Home está na raiz, o evento é entregue ao Navigator raiz/sistema.

Esse comportamento vale para botão do sistema, Web e chamadas de
`maybePop`. Botões visuais de voltar continuam pertencendo à página.

## Seleção por código

Preferir:

```dart
navigationController.selectSection(AppShellSection.library);
```

Durante a compatibilidade, callbacks antigos podem usar:

```dart
navigationController.selectIndex(AppShellSection.library.index);
```

Índices literais não devem ser adicionados.

## Nested Navigation

Cada seção possui:

- `GlobalKey<NavigatorState>` estável;
- rota raiz declarativa;
- rotas internas nomeadas;
- observer para atualizar o estado de retorno;
- `HeroController` independente.

Rotas legadas chamadas com `Navigator.of(context).push(...)` entram
naturalmente na pilha da seção porque as páginas raiz estão abaixo do
`SectionNavigator`.

## Acessibilidade

- labels dos cinco destinos permanecem visíveis;
- estado selecionado é anunciado por Semantics;
- ícones não são o único indicador;
- foco e teclado seguem a ordem visual;
- largura estreita não remove labels;
- text scaling não altera a ordem das seções.

## Compatibilidade

`AppNavigationFrame`, `AppBottomNavigation` e `AppSideNavigation` não foram
apagados. O primeiro funciona como adapter; a navegação lateral não é mais
usada pelo shell oficial.

