# DS3.0-M04 — Componentes de Domínio

## Status

Implementação concluída em 24 de julho de 2026.

O marco criou a biblioteca de componentes específicos de domínio sem
implementar telas, alterar regras de negócio ou conectar integrações.

## Entrega

- 149 APIs solicitadas disponíveis no barrel público;
- 143 classes novas;
- 6 componentes existentes reutilizados;
- 11 domínios com barrel próprio;
- modelos de apresentação imutáveis;
- showcase isolado com uma página por domínio;
- suíte automatizada M04;
- documentação de catálogo, migração e auditoria.

## Domínios

| Domínio | Total |
| --- | ---: |
| Home | 12 |
| Planos | 14 |
| Treino | 21 |
| Atividades | 11 |
| Corridas | 14 |
| Passos | 9 |
| Biblioteca | 15 |
| Nutrição | 19 |
| Perfil | 15 |
| Premium | 9 |
| Configurações | 10 |
| **Total** | **149** |

## Arquitetura

O catálogo está em:

```text
lib/core/design_system/components/domain/
```

`lib/design_system` continua proprietário de tema, tokens e componentes
maduros. O diretório `lib/core/design_system/components` funciona como fachada
modular e camada de composição, sem criar uma segunda implementação do tema.

## Componentes reutilizados

`FitQuickActionCard`, `FitCoachInsightCard`, `FitPlanCard`,
`FitActivityCard`, `FitExerciseCard` e `FitProfileHeader`.

## Integrações deliberadamente ausentes

- GPS e mapa;
- câmera e scanner;
- pagamento e assinatura;
- serviços, repositories e providers;
- navegação global;
- timers internos;
- cálculo de nutrição, corrida, treino ou XP.

Todas essas responsabilidades são representadas por estado, conteúdo e
callbacks fornecidos pelo consumidor.

## Showcase

Execute:

```bash
flutter run -t lib/debug/design_system_showcase/main.dart
```

As onze novas rotas são locais ao showcase e não aparecem no aplicativo
principal.

## Testes

Arquivo:

```text
test/design_system/domain_components_m04_test.dart
```

Cobertura:

- renderização dos 12 componentes representativos obrigatórios;
- callbacks;
- loading e disabled;
- texto longo e text scaling;
- tema escuro e Semantics;
- barrels;
- fronteiras sem services ou plataforma.

## Compatibilidade

Nenhum widget atual foi removido. O mapa incremental está em
[DOMAIN_COMPONENT_MIGRATION_MAP.md](./DOMAIN_COMPONENT_MIGRATION_MAP.md).

## Pendências

- golden tests e comparação por pixel;
- validação manual do showcase em Android, iOS, web e tablet;
- integração por micro-sprint nas telas existentes;
- validação final dos tokens dimensionais provisórios;
- hover/focus e navegação por teclado em web.

## Recomendação para M05

O próximo marco deve migrar um único fluxo de baixo risco usando o mapa de
migração, com baseline visual, teste de comportamento e rollback simples.
Nenhuma tela deve ser migrada em lote.

## Validação final

```text
dart format .    490 arquivos verificados
flutter analyze  No issues found
flutter test     123 testes aprovados
```

A suíte M04 possui oito testes e também percorre as onze páginas do showcase
em largura de `320 px`.
