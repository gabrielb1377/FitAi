import '../models/user_context.dart';

abstract class AIService {
  const AIService();

  Future<String> gerarTreinoPersonalizado(UserContext context);

  Future<String> responderPergunta({
    required UserContext context,
    required String pergunta,
  });

  Future<String> analisarEvolucao(UserContext context);

  Future<String> sugerirProgressao({
    required UserContext context,
    required String exercicio,
  });

  Future<String> gerarInsightAtividades(UserContext context);

  Future<String> explicarExercicio({
    required UserContext context,
    required String exercicio,
  });
}
