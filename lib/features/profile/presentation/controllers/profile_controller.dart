import 'package:flutter/foundation.dart';

import '../../data/profile_repository.dart';
import '../../domain/profile_models.dart';

/// Estado de leitura da pagina principal de Perfil.
enum ProfileLoadStatus { initial, loading, ready, error }

/// Estado imutavel consumido pela camada de apresentacao de Perfil.
class ProfileViewState {
  const ProfileViewState({
    required this.status,
    this.snapshot,
    this.errorMessage,
    this.isRefreshing = false,
  });

  const ProfileViewState.initial() : this(status: ProfileLoadStatus.initial);

  final ProfileLoadStatus status;
  final ProfileSnapshot? snapshot;
  final String? errorMessage;
  final bool isRefreshing;

  bool get hasSnapshot => snapshot != null;

  bool get isPartiallyAvailable => snapshot?.hasPartialData ?? false;
}

/// Coordena leitura e atualizacao do [ProfileRepository] sem manter dados.
class ProfileController extends ChangeNotifier {
  ProfileController({required this._repository});

  final ProfileRepository _repository;
  ProfileViewState _state = const ProfileViewState.initial();
  bool _loading = false;

  ProfileViewState get state => _state;

  Future<void> load() => _load(refresh: false);

  Future<void> refresh() => _load(refresh: true);

  Future<void> _load({required bool refresh}) async {
    if (_loading) return;
    _loading = true;
    _state = ProfileViewState(
      status: refresh && _state.hasSnapshot
          ? ProfileLoadStatus.ready
          : ProfileLoadStatus.loading,
      snapshot: _state.snapshot,
      isRefreshing: refresh,
    );
    notifyListeners();

    try {
      final snapshot = await _repository.load();
      _state = ProfileViewState(
        status: ProfileLoadStatus.ready,
        snapshot: snapshot,
      );
    } on Object {
      _state = ProfileViewState(
        status: _state.hasSnapshot
            ? ProfileLoadStatus.ready
            : ProfileLoadStatus.error,
        snapshot: _state.snapshot,
        errorMessage: 'Nao foi possivel carregar o Perfil agora.',
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
