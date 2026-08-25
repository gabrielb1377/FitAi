import 'dart:async';

import 'package:flutter/material.dart';
import '../models/treino_model.dart';
import 'storage_service.dart';

class TreinoService extends ChangeNotifier {
  TreinoService._();

  static final TreinoService instance = TreinoService._();

  final List<TreinoModel> _treinos = [];
  bool _initialized = false;
  bool _isLoading = false;
  Object? _loadError;

  List<TreinoModel> get treinos => List.unmodifiable(_treinos);
  bool get isInitialized => _initialized;
  bool get isLoading => _isLoading;
  Object? get loadError => _loadError;

  Future<void> initialize({bool force = false}) async {
    if (_isLoading || (_initialized && !force)) return;

    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      final saved = await StorageService.carregarTreinos();
      final byId = <String, TreinoModel>{
        for (final workout in _treinos) workout.id: workout,
        for (final workout in saved) workout.id: workout,
      };
      _treinos
        ..clear()
        ..addAll(byId.values);
      _initialized = true;
    } catch (error) {
      _loadError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void adicionarTreino(TreinoModel treino) {
    unawaited(adicionarTreinoComPersistencia(treino));
  }

  Future<void> adicionarTreinoComPersistencia(TreinoModel treino) async {
    // The device is the source of truth for creation; remote delivery is queued
    // by StorageService only after this durable local write completes.
    await StorageService.salvarTreino(treino);

    _initialized = true;
    _loadError = null;
    final index = _treinos.indexWhere((item) => item.id == treino.id);

    if (index >= 0) {
      _treinos[index] = treino;
    } else {
      _treinos.add(treino);
    }

    notifyListeners();
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
