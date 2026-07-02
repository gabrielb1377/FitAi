import '../models/fitai_memory_model.dart';
import 'storage_service.dart';

class FitAIMemoryService {
  const FitAIMemoryService();

  Future<FitAIMemoryModel> carregarMemoria() async {
    return await StorageService.carregarFitAIMemory() ??
        const FitAIMemoryModel();
  }

  Future<void> salvarMemoria(FitAIMemoryModel memoria) {
    return StorageService.salvarFitAIMemory(memoria);
  }

  Future<void> limparMemoria() {
    return StorageService.limparFitAIMemory();
  }

  Future<void> atualizarObjetivo(String objetivo) async {
    final memoria = await carregarMemoria();
    await salvarMemoria(memoria.copyWith(objetivo: objetivo.trim()));
  }

  Future<void> atualizarPeso(double peso) async {
    final memoria = await carregarMemoria();
    await salvarMemoria(memoria.copyWith(peso: peso));
  }

  Future<void> atualizarLesoes(List<String> lesoes) async {
    final memoria = await carregarMemoria();
    await salvarMemoria(memoria.copyWith(lesoes: _limparLista(lesoes)));
  }

  Future<String> gerarResumoParaIA({FitAIMemoryModel? memoria}) async {
    final dados = memoria ?? await carregarMemoria();
    final linhas = <String>[];

    void add(String label, String value) {
      final texto = value.trim();
      if (texto.isEmpty) return;
      linhas.add('$label: $texto');
    }

    add('Nome', dados.nome);
    if (dados.idade > 0) add('Idade', '${dados.idade} anos');
    if (dados.peso > 0) add('Peso', '${dados.peso.toStringAsFixed(1)} kg');
    if (dados.altura > 0) {
      add('Altura', '${dados.altura.toStringAsFixed(0)} cm');
    }
    add('Objetivo', dados.objetivo);
    add('Nivel de experiencia', dados.nivelExperiencia);
    add('Local de treino', dados.localTreino);
    if (dados.equipamentos.isNotEmpty) {
      add('Equipamentos', dados.equipamentos.join(', '));
    }
    if (dados.lesoes.isNotEmpty) add('Lesoes', dados.lesoes.join(', '));
    if (dados.exerciciosFavoritos.isNotEmpty) {
      add('Exercicios favoritos', dados.exerciciosFavoritos.join(', '));
    }
    if (dados.exerciciosEvitados.isNotEmpty) {
      add('Exercicios evitados', dados.exerciciosEvitados.join(', '));
    }
    if (dados.diasDisponiveis.isNotEmpty) {
      add('Dias disponiveis', dados.diasDisponiveis.join(', '));
    }
    if (dados.tempoMedioTreino > 0) {
      add('Tempo medio de treino', '${dados.tempoMedioTreino} min');
    }
    add('Horario preferido', dados.horarioPreferido);
    add('Observacoes', dados.observacoes);

    if (linhas.isEmpty) {
      return 'Memoria FITAI: sem preferencias salvas ainda.';
    }

    return 'Memoria FITAI:\n${linhas.map((linha) => '- $linha').join('\n')}';
  }

  List<String> _limparLista(List<String> itens) {
    return itens
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
