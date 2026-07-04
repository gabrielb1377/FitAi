# Regras do Codex para o FITAI

Este arquivo define regras para o Codex trabalhar no projeto FITAI sem quebrar funcionalidades existentes.

## Regras gerais

- Nao alterar logica quando o pedido for apenas UI.
- Nao alterar `StorageService` sem necessidade.
- Nao alterar IA sem pedido explicito.
- Nao criar dependencias novas.
- Nao sobrescrever telas inteiras sem pedido explicito.
- Rodar `flutter analyze` obrigatoriamente apos alteracoes.

## Organizacao de codigo

- Pages devem ter no maximo 250 linhas.
- Widgets devem ter no maximo 150 linhas.
- Separar UI em widgets pequenos.
- Manter a logica principal nas pages ou services adequados.
- Widgets devem receber parametros e conter apenas UI sempre que possivel.

## Design e UI

- Usar `AppTheme`, `AppColors` e componentes existentes.
- Manter o tema escuro FITAI.
- Preferir abordagem mobile-first.
- Evitar layouts em duas colunas para treino em andamento.
- Preservar a identidade visual premium do FITAI.
