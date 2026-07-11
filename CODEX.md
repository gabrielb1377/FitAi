# Codex - FitIA Flutter

Leia primeiro o guia completo em [..\docs\CODEX_RULES.md](..\docs\CODEX_RULES.md).

- Preserve Android, Web e Windows, alem de navegacao, scroll e estados atuais.
- Nao altere logica quando o pedido for somente UI, nem altere `StorageService` ou IA sem pedido explicito.
- Nao crie dependencias novas e nao sobrescreva telas inteiras sem necessidade comprovada.
- O app e offline-first: SharedPreferences e cache local permanecem como fallback; backend indisponivel nao bloqueia fluxos basicos.
- Servicos centrais controlam corrida, passos, sincronizacao, IA e autenticacao. Telas nao criam estado global, timers duplicados ou logica paralela.
- Reutilize AppTheme e componentes FitIA. Priorize UI mobile-first, acessivel e sem excesso de cards, gradientes, animacoes ou pop-ups.
- Preserve o tema escuro e a identidade visual premium do FitIA; evite layouts de duas colunas no treino em andamento.
- Pages devem ter no maximo 250 linhas e widgets no maximo 150 linhas. Separe UI em widgets pequenos e mantenha a logica em pages ou services adequados.
- Trate loading, vazio, erro e offline. Use serializacao segura e mantenha compatibilidade com dados antigos.
- Nao use `BuildContext` apos `await` sem `mounted` e nunca use `async` dentro de `setState`.
- Nunca coloque `OPENAI_API_KEY` ou outro segredo no aplicativo.
- Execute `flutter analyze` para qualquer alteracao Flutter e relate testes que nao foram executados.
