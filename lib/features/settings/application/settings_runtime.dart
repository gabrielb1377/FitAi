import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/auth/local_account_data_boundary.dart';
import '../data/settings_repository.dart';
import '../domain/settings_models.dart';

enum SettingsLoadStatus { initial, loading, ready, error }

class SettingsViewState {
  const SettingsViewState({required this.status, this.snapshot, this.error});

  const SettingsViewState.initial() : this(status: SettingsLoadStatus.initial);

  final SettingsLoadStatus status;
  final SettingsSnapshot? snapshot;
  final Object? error;

  bool get isReady => status == SettingsLoadStatus.ready && snapshot != null;
}

/// Cache de leitura para preferencias que precisam ser consultadas por telas
/// existentes sem transformar seus modelos de dominio em configuracoes.
abstract final class WorkoutSettingsRuntime {
  static RestSettings _rest = RestSettings.defaults();
  static UnitSettings _units = UnitSettings.defaults();

  static RestSettings get rest => _rest;
  static UnitSettings get units => _units;

  static void apply(AppSettings value) {
    _rest = value.account.rest;
    _units = value.account.units;
  }
}

/// Controlador global de preferencias. Ele nao concentra dados de Perfil,
/// treinos ou atividades; apenas publica a preferencia de apresentacao.
class SettingsController extends ChangeNotifier {
  SettingsController({required this.repository});

  final SettingsRepository repository;
  SettingsViewState _state = const SettingsViewState.initial();

  SettingsViewState get state => _state;

  Future<void> load() async {
    if (_state.status == SettingsLoadStatus.loading) return;
    _state = SettingsViewState(
      status: SettingsLoadStatus.loading,
      snapshot: _state.snapshot,
    );
    notifyListeners();
    try {
      final snapshot = await repository.load();
      WorkoutSettingsRuntime.apply(snapshot.settings);
      _state = SettingsViewState(
        status: SettingsLoadStatus.ready,
        snapshot: snapshot,
      );
    } on Object catch (error) {
      _state = SettingsViewState(
        status: SettingsLoadStatus.error,
        snapshot: _state.snapshot,
        error: error,
      );
    }
    notifyListeners();
  }

  Future<void> update(AppSettings Function(AppSettings value) transform) async {
    final current = _state.snapshot;
    if (current == null) return;
    try {
      final snapshot = await repository.update(current, transform);
      WorkoutSettingsRuntime.apply(snapshot.settings);
      _state = SettingsViewState(
        status: SettingsLoadStatus.ready,
        snapshot: snapshot,
      );
    } on Object catch (error) {
      _state = SettingsViewState(
        status: SettingsLoadStatus.error,
        snapshot: current,
        error: error,
      );
    }
    notifyListeners();
  }
}

/// Ponto de acesso inicializado antes do app e reutilizado pelas paginas.
abstract final class SettingsRuntime {
  static final SettingsController controller = SettingsController(
    repository: SettingsRepository.local(),
  );

  static bool _observingAccount = false;

  static Future<void> initialize() async {
    if (!_observingAccount) {
      _observingAccount = true;
      AccountSessionLifecycle.revision.addListener(_reloadForAccountChange);
    }
    await controller.load();
  }

  static void _reloadForAccountChange() {
    unawaited(controller.load());
  }
}
