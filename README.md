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

## Corridas com GPS

As corridas sao controladas por `lib/services/running_session_service.dart`.
Home, Atividades e Corridas apenas observam esse servico, entao a sessao continua ativa ao trocar de tela.

O servico usa `geolocator`, persiste a sessao ativa em SharedPreferences, registra rota por coordenadas e finaliza salvando no historico local. Ao salvar a corrida, o sync existente tenta enviar para `POST /sync/running`; se o backend estiver offline, a fila local de sincronizacao assume.

## Passos com Health Connect

Os passos sao controlados por `lib/services/steps_service.dart`. Home, Atividades e PassosPage consomem esse servico para mostrar passos de hoje, meta diaria, progresso, media semanal, melhor dia da semana, passos restantes, distancia estimada e calorias.

No Android, o app usa `health_connector` para ler `Steps` do Health Connect. Toque em "Sincronizar agora" para solicitar permissao e carregar passos reais. Se Health Connect nao estiver instalado, indisponivel ou a permissao for negada, o app continua usando o cache local em SharedPreferences.

No Windows/Web, o servico nao chama o plugin e usa apenas fallback local, mantendo o app testavel no Edge/Windows.

Para testar em Android real:

1. Instale ou abra o Health Connect no aparelho.
2. Garanta que algum app/dispositivo esteja escrevendo passos no Health Connect.
3. Rode o FitIA no Android.
4. Abra Home, Atividades ou Passos e toque em "Sincronizar agora".
5. Conceda a permissao de passos.

Ao sincronizar, o app salva localmente, tenta enviar `POST /steps/sync` para o backend e usa a fila offline se o backend estiver indisponivel. XP de meta diaria usa `XpConfig.passosMetaDiaria` e so e concedido uma vez por dia.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
