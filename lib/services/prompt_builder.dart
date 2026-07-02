import '../models/user_context.dart';

class PromptBuilder {
  const PromptBuilder();

  String gerarTreinoPersonalizado(UserContext context) {
    return '''
Voce e o coach do FITAI.
Crie um treino personalizado usando o contexto do usuario.

${_contextoBase(context)}

Requisitos:
- respeitar objetivo, nivel, lesoes e equipamentos disponiveis;
- sugerir estrutura clara de exercicios;
- incluir intensidade e cuidados.
''';
  }

  String responderPergunta(UserContext context, String pergunta) {
    return '''
Voce e o assistente fitness do FITAI.
Responda de forma segura, curta e pratica.

${_contextoBase(context)}

Pergunta do usuario:
$pergunta
''';
  }

  String analisarEvolucao(UserContext context) {
    return '''
Analise a evolucao do usuario no FITAI.

${_contextoBase(context)}

Use historico, atividades, consistencia e sinais de recuperacao.
Retorne pontos fortes, alertas e proximos passos.
''';
  }

  String sugerirProgressao(UserContext context, String exercicio) {
    return '''
Sugira progressao de carga/repeticoes para o exercicio abaixo.

Exercicio: $exercicio

${_contextoBase(context)}

Considere historico, nivel, objetivo e seguranca.
''';
  }

  String gerarInsightAtividades(UserContext context) {
    return '''
Gere insights sobre atividades do usuario no FITAI.

${_contextoBase(context)}

Considere passos, corrida, metas, calorias, sequencia e recuperacao.
''';
  }

  String explicarExercicio(UserContext context, String exercicio) {
    return '''
Explique o exercicio abaixo para o usuario do FITAI.

Exercicio: $exercicio

${_contextoBase(context)}

Inclua execucao, musculos, erros comuns e cuidados.
''';
  }

  String _contextoBase(UserContext context) {
    return '''
Contexto do usuario:
- Nome: ${_valor(context.nome, 'Nao informado')}
- Objetivo: ${_valor(context.objetivo, 'Saude e condicionamento')}
- Peso: ${context.peso > 0 ? '${context.peso.toStringAsFixed(1)} kg' : 'Nao informado'}
- Altura: ${context.altura > 0 ? '${context.altura.toStringAsFixed(0)} cm' : 'Nao informada'}
- Idade: ${context.idade > 0 ? context.idade : 'Nao informada'}
- Nivel: ${_valor(context.nivel, 'Iniciante')}
- Lesoes/limitacoes: ${context.lesoes.isEmpty ? 'Nenhuma informada' : context.lesoes.join(', ')}
- Equipamentos: ${context.equipamentos.isEmpty ? 'Nao informado' : context.equipamentos.join(', ')}
- Historico e memoria FITAI: ${_valor(context.historicoResumo, 'Sem historico suficiente')}
- Atividades: ${_valor(context.atividadesResumo, 'Sem dados de atividades suficientes')}
''';
  }

  String _valor(String value, String fallback) {
    final texto = value.trim();
    return texto.isEmpty ? fallback : texto;
  }
}
