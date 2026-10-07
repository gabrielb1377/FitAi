import 'dart:async';

import 'package:flutter/material.dart';
import '../models/treino_model.dart';
import 'storage_service.dart';
import '../core/exercises/plan_mutation_guard.dart';

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
      _treinos
        ..clear()
        ..addAll(saved);
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

  Future<void> adicionarTreinoComPersistencia(
    TreinoModel treino, {
    PlanMutationGuard? mutationGuard,
  }) async {
    // The device is the source of truth for creation; remote delivery is queued
    // by StorageService only after this durable local write completes.
    await StorageService.salvarTreino(treino, mutationGuard: mutationGuard);

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

  /// Exclui a definicao persistida do plano antes de refletir a lista em
  /// memoria. O journal de sessoes permanece intacto para proteger uma sessao
  /// ativa ou historico ja concluido.
  Future<bool> removerTreinoComPersistencia(String id) async {
    final removed = await StorageService.removerTreino(id);
    if (!removed) return false;
    _treinos.removeWhere((treino) => treino.id == id);
    notifyListeners();
    return true;
  }

  @Deprecated('Use removerTreinoComPersistencia para manter a exclusao local.')
  void removerTreino(String id) {
    unawaited(removerTreinoComPersistencia(id));
  }
}
