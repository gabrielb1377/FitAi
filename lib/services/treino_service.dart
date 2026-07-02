import 'package:flutter/material.dart';
import '../models/treino_model.dart';

class TreinoService extends ChangeNotifier {
  TreinoService._();

  static final TreinoService instance = TreinoService._();

  final List<TreinoModel> _treinos = [];

  List<TreinoModel> get treinos => List.unmodifiable(_treinos);

  void adicionarTreino(TreinoModel treino) {
    _treinos.add(treino);
    notifyListeners();
  }

  void removerTreino(String id) {
    _treinos.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}