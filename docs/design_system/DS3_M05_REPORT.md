# DS3.0-M05 - Arquitetura Visual Oficial

## Status

Implementação concluída em 24 de julho de 2026.

## Objetivo

Criar a infraestrutura definitiva do shell e iniciar a organização
feature-first sem implementar em lote as telas oficiais.

## Auditoria inicial

Antes da migração:

- a ordem era `Home | Planos | Biblioteca | Atividades | Perfil`;
- Web e tablet substituíam a Bottom Navigation por navegação lateral;
- as cinco raízes eram preservadas por `IndexedStack`;
- não havia pilha independente por seção;
- Auth entrava no app por uma instância direta de `DashboardPage`;
- rotas internas usavam majoritariamente `MaterialPageRoute`.

## Entrega

- ordem oficial `Home | Planos | Atividades | Biblioteca | Perfil`;
- `MainScaffold`;
- Bottom Navigation oficial em todas as larguras;
- `NavigationController`;
- `SectionRouter` e `SectionNavigator`;
- cinco stacks aninhados e preservados;
- constantes de rotas raiz e de módulos;
- parser de deep links sem bypass de autenticação;
- placeholder oficial para rotas reservadas;
- adapters feature-first para as páginas existentes;
- compatibilidade com `AppNavigationFrame` e navegação legada.

## Estrutura criada

Foram criados `39` arquivos (`34` Dart e `5` Markdown) e atualizados `8`
arquivos existentes.

```text
lib/core/navigation/
lib/features/home/presentation/{controllers,pages,routes,widgets}/
lib/features/plans/presentation/{controllers,pages,routes,widgets}/
lib/features/activities/presentation/{controllers,pages,routes,widgets}/
lib/features/library/presentation/{controllers,pages,routes,widgets}/
lib/features/profile/presentation/{controllers,pages,routes,widgets}/
docs/architecture/
test/navigation/
```

## Funcionalidades preservadas

- Auth e Developer Mode;
- sincronização automática;
- corrida e passos;
- Planos e execução de treino;
- Biblioteca e cache;
- Perfil e dados locais;
- callbacks existentes da Home;
- rotas imperativas das páginas antigas.

## Não alterado

- backend;
- contratos de API;
- models;
- services de domínio;
- providers;
- persistência;
- Official UI;
- dependências do `pubspec.yaml`.

## Testes adicionados

`test/navigation/official_navigation_test.dart` cobre:

- ordem e paths oficiais;
- índices seguros;
- parser de deep links do app e Web;
- contrato do roteador raiz;
- Bottom Navigation em viewport de 1200 px;
- ausência de navegação lateral no shell;
- preservação de pilha ao trocar de seção;
- placeholder de rota reservada.

O teste legado do shell foi atualizado para a nova ordem oficial.

## Pendências deliberadas

- migrar chamadas internas de `MaterialPageRoute` para rotas nomeadas;
- conectar rotas reservadas quando cada página for migrada;
- implementar entrega de deep link após autenticação em produção;
- validar links universais e App Links por plataforma;
- remover adapters somente após zerar consumidores legados;
- comparar visualmente cada tela em suas micro-sprints.

## Riscos

- páginas antigas podem depender implicitamente do Navigator mais próximo;
- rotas profundas exigirão contratos tipados de argumentos;
- integrações de deep link nativas ainda não estão configuradas;
- manter adapters por muito tempo pode ampliar a superfície de compatibilidade.

## Validação

```text
dart format .    524 arquivos verificados, 0 alterados
flutter analyze  No issues found
flutter test     130 testes aprovados
```

`flutter run -d edge --debug --no-resident` iniciou e encerrou corretamente.
Uma segunda execução residente validou hot reload em aproximadamente `2,3 ms`.
O backend local estava indisponível e o aplicativo preservou o fluxo offline.

`flutter run -d windows` não compilou porque o ambiente não possui um
toolchain compatível do Visual Studio. Essa é uma pendência de ambiente, não
um erro reportado pelo analisador ou pela suíte Flutter.

## Próximo passo recomendado

Migrar uma única rota interna de baixo risco para o `SectionRouter`, com teste
de entrada, retorno, estado preservado e comparação visual. Não iniciar uma
migração em lote.
