import 'package:flutter/foundation.dart';

import '../models/treino_model.dart';
import 'storage_service.dart';

class DivisaoTreinoSemanal {
  final String codigo;
  final String nome;
  final List<String> dias;

  const DivisaoTreinoSemanal({
    required this.codigo,
    required this.nome,
    required this.dias,
  });
}

class TreinoService extends ChangeNotifier {
  TreinoService._internal();

  static final TreinoService instance = TreinoService._internal();

  // Base para futura geracao semanal por IA: ABC, ABCD, ABCDE,
  // push pull legs, full body e upper/lower.
  static const List<DivisaoTreinoSemanal> divisoesSemanaisPlanejadas = [
    DivisaoTreinoSemanal(
      codigo: "ABC",
      nome: "ABC",
      dias: [
        "A Peito + Triceps",
        "B Costas + Biceps",
        "C Pernas + Panturrilha",
      ],
    ),
    DivisaoTreinoSemanal(
      codigo: "ABCD",
      nome: "ABCD",
      dias: ["A Peito", "B Costas", "C Pernas", "D Ombros + Bracos"],
    ),
    DivisaoTreinoSemanal(
      codigo: "ABCDE",
      nome: "ABCDE",
      dias: ["A Peito", "B Costas", "C Pernas", "D Ombros", "E Bracos"],
    ),
    DivisaoTreinoSemanal(
      codigo: "FULL_BODY",
      nome: "Full body",
      dias: ["Full Body A", "Full Body B", "Full Body C"],
    ),
    DivisaoTreinoSemanal(
      codigo: "PUSH_PULL_LEGS",
      nome: "Push Pull Legs",
      dias: [
        "Push Peito + Ombros + Triceps",
        "Pull Costas + Biceps",
        "Legs Pernas + Gluteos + Panturrilha",
      ],
    ),
    DivisaoTreinoSemanal(
      codigo: "UPPER_LOWER",
      nome: "Upper/lower",
      dias: ["Upper", "Lower"],
    ),
  ];

  final List<TreinoModel> _treinos = [];
  bool _carregado = false;

  List<TreinoModel> get treinos => List.unmodifiable(_treinos);

  Future<void> carregarTreinos() async {
    if (_carregado) return;

    final treinosSalvos = await StorageService.carregarTreinos();
    _treinos
      ..clear()
      ..addAll(treinosSalvos);

    _carregado = true;
    notifyListeners();
  }

  Future<void> adicionarTreino(TreinoModel treino) async {
    if (!_carregado) await carregarTreinos();

    _treinos.insert(0, treino);
    await _reescreverTreinosNoStorage();
    notifyListeners();
  }

  Future<void> removerTreino(String id) async {
    if (!_carregado) await carregarTreinos();

    _treinos.removeWhere((t) => t.id == id);
    await _reescreverTreinosNoStorage();
    notifyListeners();
  }

  Future<void> editarTreino(TreinoModel treino) async {
    if (!_carregado) await carregarTreinos();

    final index = _treinos.indexWhere((t) => t.id == treino.id);

    if (index != -1) {
      _treinos[index] = treino;
      await _reescreverTreinosNoStorage();
      notifyListeners();
    }
  }

  Future<void> reordenarTreinos(int oldIndex, int newIndex) async {
    if (!_carregado) await carregarTreinos();

    if (oldIndex < 0 || oldIndex >= _treinos.length) return;

    var destino = newIndex;
    if (destino < 0) destino = 0;
    if (destino > _treinos.length - 1) destino = _treinos.length - 1;

    final treino = _treinos.removeAt(oldIndex);
    _treinos.insert(destino, treino);

    await _reescreverTreinosNoStorage();
    notifyListeners();
  }

  TreinoModel? buscarTreino(String id) {
    try {
      return _treinos.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> limparTreinos() async {
    _treinos.clear();
    await StorageService.apagarTreinos();
    notifyListeners();
  }

  Future<void> _reescreverTreinosNoStorage() async {
    await StorageService.apagarTreinos();

    for (final treino in _treinos) {
      await StorageService.salvarTreino(treino);
    }
  }
}
