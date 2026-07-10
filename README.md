# fitai

A new Flutter project.

## Backend IA

O gerador de treino com IA tenta chamar o backend real em:

```text
POST http://localhost:3001/ai/generate-workout
```

Para usar a API real, deixe o backend `C:\fitai-backend` rodando com:

```powershell
cd C:\fitai-backend
npm run dev
```

O formulario permite escolher de 6 a 10 exercicios minimos por dia. Esse valor e enviado como `minExerciciosPorDia` para o backend, e o fallback local tambem tenta respeitar o minimo escolhido.

Se o backend estiver desligado, indisponivel ou retornar uma resposta invalida, o app continua funcionando e usa a geracao local atual como fallback. A chave OpenAI fica somente no backend; ela nao deve ser colocada no Flutter.

## Coach FitIA

Os insights personalizados tentam chamar:

```text
POST http://localhost:3001/coach/insights
```

Quando houver token no futuro, o servico aceita `Authorization: Bearer <token>`. Sem login, o Flutter envia `contextoLocal` com perfil, planos, historico de treino, series, metas, recordes e corridas salvos no aparelho.

Se o backend estiver offline ou retornar erro, as telas continuam usando os insights locais do app.

## Sincronizacao offline-first

O app continua salvando primeiro no SharedPreferences. Depois tenta enviar perfil, metas, recordes, planos, historico de treino e corridas para `C:\fitai-backend`.

Se o backend estiver offline, o item fica em uma fila local pendente e o app tenta reenviar automaticamente quando abrir ou a cada nova tentativa de sync. O header `X-FitIA-Client-Id` identifica o dispositivo enquanto o login nao for obrigatorio.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
