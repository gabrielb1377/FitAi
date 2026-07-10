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

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
