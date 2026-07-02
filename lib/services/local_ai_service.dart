import '../models/user_context.dart';
import 'ai_service.dart';
import 'prompt_builder.dart';

class LocalAIService extends AIService {
  final PromptBuilder promptBuilder;

  const LocalAIService({this.promptBuilder = const PromptBuilder()});

  @override
  Future<String> gerarTreinoPersonalizado(UserContext context) async {
    final foco = _focoPorObjetivo(context.objetivo);
    final equipamentos = context.equipamentos.isEmpty
        ? 'peso corporal'
        : context.equipamentos.join(', ');
    final cuidado = context.temLesoes
        ? 'Adaptar movimentos por conta de: ${context.lesoes.join(', ')}.'
        : 'Priorizar execucao controlada e descanso adequado.';

    return '''
Treino local sugerido para ${_nome(context)}:
- Objetivo: ${context.objetivo}
- Nivel: ${context.nivel}
- Foco: $foco
- Equipamentos: $equipamentos
- Estrutura: aquecimento leve, 5 a 7 exercicios principais e finalizacao curta.
- Cuidado: $cuidado
''';
  }

  @override
  Future<String> responderPergunta({
    required UserContext context,
    required String pergunta,
  }) async {
    final perguntaNormalizada = pergunta.toLowerCase();

    if (perguntaNormalizada.contains('dor') ||
        perguntaNormalizada.contains('lesao') ||
        perguntaNormalizada.contains('lesão')) {
      return 'Se houver dor aguda, reduza intensidade e procure avaliacao profissional. No FITAI, ajuste o treino para movimentos sem dor.';
    }

    if (perguntaNormalizada.contains('descanso')) {
      return 'Para ${_nome(context)}, uma boa regra local e alternar dias intensos com dias leves, observando sono, fadiga e historico recente.';
    }

    return 'Resposta local do FITAI: mantenha consistencia, progrida aos poucos e use seu historico para ajustar intensidade.';
  }

  @override
  Future<String> analisarEvolucao(UserContext context) async {
    final historico = context.historicoResumo.trim().isEmpty
        ? 'Ainda ha poucos dados de treino.'
        : context.historicoResumo;
    final atividades = context.atividadesResumo.trim().isEmpty
        ? 'Ainda ha poucos dados de atividades.'
        : context.atividadesResumo;

    return '''
Analise local de evolucao:
- Historico: $historico
- Atividades: $atividades
- Leitura: mantenha frequencia antes de aumentar intensidade.
- Proximo passo: buscar pequena melhora semanal em passos, volume ou ritmo.
''';
  }

  @override
  Future<String> sugerirProgressao({
    required UserContext context,
    required String exercicio,
  }) async {
    final nivel = context.nivel.toLowerCase();
    final ajuste = nivel.contains('avanc')
        ? '2,5% a 5%'
        : nivel.contains('inter')
        ? '2,5%'
        : 'manter carga e melhorar tecnica';

    return 'Progressao local para $exercicio: $ajuste, somente se a ultima sessao foi concluida com boa tecnica.';
  }

  @override
  Future<String> gerarInsightAtividades(UserContext context) async {
    final atividades = context.atividadesResumo.trim();

    if (atividades.isEmpty) {
      return 'Registre passos e corridas para o FITAI gerar insights mais precisos.';
    }

    return 'Insight local de atividades: $atividades. Busque consistencia diaria e ajuste intensidade se houver fadiga.';
  }

  @override
  Future<String> explicarExercicio({
    required UserContext context,
    required String exercicio,
  }) async {
    final cuidado = context.temLesoes
        ? 'Considere suas limitacoes: ${context.lesoes.join(', ')}.'
        : 'Mantenha controle, amplitude confortavel e respiracao constante.';

    return '''
$exercicio:
- Execute com tecnica controlada.
- Priorize postura antes de carga.
- Evite compensacoes.
- $cuidado
''';
  }

  String buildPromptTreino(UserContext context) {
    return promptBuilder.gerarTreinoPersonalizado(context);
  }

  String _focoPorObjetivo(String objetivo) {
    final texto = objetivo.toLowerCase();

    if (texto.contains('hipertrof')) return 'forca, volume e progressao';
    if (texto.contains('emagrec')) return 'gasto calorico e consistencia';
    if (texto.contains('resist')) return 'capacidade aerobica e repeticoes';
    if (texto.contains('forca')) return 'movimentos base e descanso maior';
    return 'condicionamento geral e aderencia';
  }

  String _nome(UserContext context) {
    final nome = context.nome.trim();
    return nome.isEmpty ? 'voce' : nome;
  }
}
