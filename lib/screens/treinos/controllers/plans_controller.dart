import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/dev_data.dart';
import '../../../core/config/dev_fixtures.dart';
import '../../../models/treino_model.dart';
import '../../../services/network_service.dart';
import '../../../services/treino_service.dart';
import 'plan_progress_snapshot.dart';

class PlansController extends ChangeNotifier {
  PlansController({
    TreinoService? workoutService,
    this._devDataService = const DevDataService(),
    this._progressLoader = const PlanProgressLoader(),
    Future<bool> Function()? checkBackend,
    this.useDeveloperFallback = true,
  }) : _workoutService = workoutService ?? TreinoService.instance,
       _checkBackend = checkBackend ?? NetworkService().isBackendAvailable {
    _workoutService.addListener(_onWorkoutsChanged);
  }

  final TreinoService _workoutService;
  final DevDataService _devDataService;
  final PlanProgressLoader _progressLoader;
  final Future<bool> Function() _checkBackend;
  final bool useDeveloperFallback;

  bool isLoading = true;
  bool isOffline = false;
  Object? error;
  List<TreinoModel> _debugFallback = const [];
  Map<String, PlanProgressSnapshot> _progress = const {};
  bool _reloadingProgress = false;

  List<TreinoModel> get plans {
    final real = _workoutService.treinos
        .where((workout) => workout.isPlanoPrincipal)
        .toList(growable: false);
    return real.isNotEmpty ? real : _debugFallback;
  }

  PlanProgressSnapshot progressFor(TreinoModel plan) {
    return _progress[plan.id] ?? PlanProgressSnapshot.empty(plan);
  }

  Future<void> initialize({bool force = false}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    await _workoutService.initialize(force: force);
    final realPlans = _workoutService.treinos
        .where((workout) => workout.isPlanoPrincipal)
        .toList(growable: false);

    if (realPlans.isEmpty && useDeveloperFallback) {
      final runtime = await _devDataService.resolve();
      _debugFallback = runtime.useFakeWorkout
          ? DevFixtures.workouts
          : const <TreinoModel>[];
    } else {
      _debugFallback = const [];
    }

    await _reloadProgress();
    error = _workoutService.loadError;
    isLoading = false;
    notifyListeners();
    unawaited(_updateConnectivity());
  }

  Future<void> _updateConnectivity() async {
    final available = await _checkBackend();
    final offline = !available;
    if (offline == isOffline) return;
    isOffline = offline;
    notifyListeners();
  }

  void _onWorkoutsChanged() {
    if (_workoutService.treinos.isNotEmpty) _debugFallback = const [];
    notifyListeners();
    unawaited(_reloadProgress());
  }

  Future<void> _reloadProgress() async {
    if (_reloadingProgress) return;
    _reloadingProgress = true;
    try {
      _progress = await _progressLoader.load(plans);
    } catch (loadError) {
      if (kDebugMode) {
        debugPrint('[PlansController] Historico indisponivel: $loadError');
      }
    } finally {
      _reloadingProgress = false;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _workoutService.removeListener(_onWorkoutsChanged);
    super.dispose();
  }
}
