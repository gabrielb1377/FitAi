import '../models/user_context.dart';
import 'ai_service.dart';
import 'fitai_memory_service.dart';
import 'local_ai_service.dart';

class AIRepository {
  final AIService service;
  final FitAIMemoryService memoryService;

  const AIRepository({
    this.service = const LocalAIService(),
    this.memoryService = const FitAIMemoryService(),
  });

  const AIRepository.withService(
    this.service, {
    this.memoryService = const FitAIMemoryService(),
  });

  Future<String> gerarTreinoPersonalizado(UserContext context) async {
    return service.gerarTreinoPersonalizado(await _contextoComMemoria(context));
  }

  Future<String> responderPergunta({
    required UserContext context,
    required String pergunta,
  }) async {
    return service.responderPergunta(
      context: await _contextoComMemoria(context),
      pergunta: pergunta,
    );
  }

  Future<String> analisarEvolucao(UserContext context) async {
    return service.analisarEvolucao(await _contextoComMemoria(context));
  }

  Future<String> sugerirProgressao({
    required UserContext context,
    required String exercicio,
  }) async {
    return service.sugerirProgressao(
      context: await _contextoComMemoria(context),
      exercicio: exercicio,
    );
  }

  Future<String> gerarInsightAtividades(UserContext context) async {
    return service.gerarInsightAtividades(await _contextoComMemoria(context));
  }

  Future<String> explicarExercicio({
    required UserContext context,
    required String exercicio,
  }) async {
    return service.explicarExercicio(
      context: await _contextoComMemoria(context),
      exercicio: exercicio,
    );
  }

  Future<UserContext> _contextoComMemoria(UserContext context) async {
    final memoria = await memoryService.carregarMemoria();
    final resumoMemoria = await memoryService.gerarResumoParaIA(
      memoria: memoria,
    );
    final historicoResumo = [
      context.historicoResumo.trim(),
      resumoMemoria.trim(),
    ].where((item) => item.isNotEmpty).join('\n\n');

    return context.copyWith(
      nome: context.nome.trim().isEmpty ? memoria.nome : context.nome,
      objetivo: _usarMemoria(context.objetivo)
          ? memoria.objetivo
          : context.objetivo,
      peso: context.peso > 0 ? context.peso : memoria.peso,
      altura: context.altura > 0 ? context.altura : memoria.altura,
      idade: context.idade > 0 ? context.idade : memoria.idade,
      nivel: _usarMemoria(context.nivel)
          ? memoria.nivelExperiencia
          : context.nivel,
      lesoes: context.lesoes.isEmpty ? memoria.lesoes : context.lesoes,
      equipamentos: context.equipamentos.isEmpty
          ? memoria.equipamentos
          : context.equipamentos,
      historicoResumo: historicoResumo,
    );
  }

  bool _usarMemoria(String value) {
    final texto = value.trim().toLowerCase();
    return texto.isEmpty ||
        texto == 'iniciante' ||
        texto == 'saude e condicionamento';
  }
}
