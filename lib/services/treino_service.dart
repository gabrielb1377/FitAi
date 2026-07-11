import 'dart:async';

import 'package:flutter/material.dart';
import '../models/treino_model.dart';
import 'storage_service.dart';

class TreinoService extends ChangeNotifier {
  TreinoService._();

  static final TreinoService instance = TreinoService._();

  final List<TreinoModel> _treinos = [];

  List<TreinoModel> get treinos => List.unmodifiable(_treinos);

  void adicionarTreino(TreinoModel treino) {
    unawaited(adicionarTreinoComPersistencia(treino));
  }

  Future<void> adicionarTreinoComPersistencia(TreinoModel treino) async {
    final index = _treinos.indexWhere((item) => item.id == treino.id);

    if (index >= 0) {
      _treinos[index] = treino;
    } else {
      _treinos.add(treino);
    }

    notifyListeners();
    await StorageService.salvarTreino(treino);
  }

  Future<bool> contemPlanoPronto(String readyPlanId) async {
    if (_treinos.any((item) => item.readyPlanId == readyPlanId)) {
      return true;
    }

    final salvos = await StorageService.carregarTreinos();
    return salvos.any((item) => item.readyPlanId == readyPlanId);
  }

  void removerTreino(String id) {
    _treinos.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
