import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/corrida_model.dart';
import '../models/running_session_model.dart';
import 'storage_service.dart';
import 'sync_service.dart';

class RunningSessionService extends ChangeNotifier {
  RunningSessionService._({DateTime Function()? clock, this._trackGps = true})
    : _clock = clock ?? DateTime.now;

  static final RunningSessionService instance = RunningSessionService._();

  @visibleForTesting
  factory RunningSessionService.forTesting({DateTime Function()? clock}) =>
      RunningSessionService._(clock: clock, trackGps: false);

  static const int _defaultCountdownSeconds = 3;
  static const double _maxAcceptedSpeedKmh = 36;
  static const double _maxAcceptedAccuracyMeters = 60;

  final DateTime Function() _clock;
  final bool _trackGps;
  final Set<String> _syncingRunIds = <String>{};
  Timer? _timer;
  Timer? _countdownTimer;
  StreamSubscription<Position>? _positionSubscription;
  RunningSessionModel? _session;
  bool _initialized = false;
  bool _initializing = false;
  bool _saving = false;
  bool _gpsConnected = false;
  bool _countdownActive = false;
  int _countdownSeconds = _defaultCountdownSeconds;
  Position? _lastAcceptedPosition;

  bool get initialized => _initialized;
  bool get saving => _saving;
  bool get gpsConnected => _gpsConnected;
  bool get countdownActive => _countdownActive;
  int get countdownSeconds => _countdownSeconds;
  RunningSessionModel? get session => _session;
  bool get hasActiveSession => _session != null && !_session!.finished;
  bool get isFinalizing => hasActiveSession && _session!.finalizing;
  bool get isRunning =>
      hasActiveSession &&
      !_session!.paused &&
      !isFinalizing &&
      !_countdownActive;
  bool get isPaused => hasActiveSession && _session!.paused && !isFinalizing;
  bool get isFinished => _session?.finished == true;
  int get elapsedSeconds => _session?.elapsedSeconds ?? 0;
  double get distanceKm => _session?.distanceKm ?? 0;
  double get currentSpeed => _session?.currentSpeed ?? 0;
  double get averageSpeed => _session?.averageSpeed ?? 0;
  double get pace => _session?.pace ?? 0;
  double? get calories => _session?.calories;
  List<RunningRoutePointModel> get route => _session?.route ?? const [];

  Future<void> initialize() async {
    if (_initialized || _initializing) return;

    _initializing = true;

    final restored = await StorageService.carregarRunningSessionAtiva();

    if (restored != null && !restored.finished) {
      _session = _restoreElapsedTime(restored);
      _lastAcceptedPosition = null;

      if (_session!.finalizing) {
        try {
          await _commitFinalization(_session!);
          _log('finalizacao recuperada');
        } catch (error) {
          _log('finalizacao pendente: $error');
        }
      } else if (!_session!.paused) {
        _ensureTimer();
        unawaited(_ensureGpsStream());
        await _persistSession();
      }

      _log('sessao restaurada');
    }

    _initialized = true;
    _initializing = false;
    notifyListeners();
    unawaited(_syncPendingRuns());
  }

  Future<void> startWithCountdown({
    int seconds = _defaultCountdownSeconds,
  }) async {
    await initialize();

    if (hasActiveSession || _countdownActive) {
      _log('inicio ignorado: ja existe corrida ativa');
      return;
    }

    _countdownTimer?.cancel();
    _countdownSeconds = math.max(1, seconds);
    _countdownActive = true;
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds <= 1) {
        timer.cancel();
        _countdownActive = false;
        unawaited(start());
        return;
      }

      _countdownSeconds -= 1;
      notifyListeners();
    });
  }

  Future<void> start() async {
    await initialize();

    if (hasActiveSession) {
      _log('inicio ignorado: ja existe corrida ativa');
      return;
    }

    final now = _clock();
    _session = RunningSessionModel.start(
      id: 'run_${now.microsecondsSinceEpoch}',
      startTime: now,
    );
    if (!await StorageService.carregarPrimeiraCorrida()) {
      await StorageService.salvarPrimeiraCorrida(true);
    }
    _lastAcceptedPosition = null;
    _countdownActive = false;
    _countdownTimer?.cancel();

    await _persistSession();
    _ensureTimer();
    unawaited(_ensureGpsStream());
    _log('corrida iniciada');
    notifyListeners();
  }

  Future<void> pause() async {
    final session = _session;
    if (session == null ||
        session.finished ||
        session.paused ||
        session.finalizing) {
      return;
    }

    final now = _clock();
    _timer?.cancel();
    _timer = null;
    await _stopGpsStream();

    _session = _advanceSessionTo(session, now).copyWith(
      paused: true,
      pausedAt: now,
      currentSpeed: 0,
      lastUpdatedAt: now,
    );
    await _persistSession();
    _log('corrida pausada');
    notifyListeners();
  }

  Future<void> resume() async {
    final session = _session;
    if (session == null ||
        session.finished ||
        !session.paused ||
        session.finalizing) {
      return;
    }

    final now = _clock();
    _session = session.copyWith(
      paused: false,
      clearPausedAt: true,
      accumulatedPausedSeconds:
          session.accumulatedPausedSeconds + _pausedSeconds(session, now),
      lastUpdatedAt: now,
    );
    await _persistSession();
    _ensureTimer();
    unawaited(_ensureGpsStream());
    _log('corrida retomada');
    notifyListeners();
  }

  Future<CorridaModel?> finish() async {
    if (_saving) return null;

    final session = _session;
    if (session == null || session.finished || session.finalizing) return null;

    _saving = true;
    notifyListeners();

    try {
      _timer?.cancel();
      _timer = null;
      _countdownTimer?.cancel();
      _countdownActive = false;
      await _stopGpsStream();

      final now = _clock();
      final finalizingSession = _advanceSessionTo(session, now).copyWith(
        endTime: now,
        paused: false,
        clearPausedAt: true,
        accumulatedPausedSeconds:
            session.accumulatedPausedSeconds + _pausedSeconds(session, now),
        finalizing: true,
        finished: false,
        currentSpeed: 0,
        lastUpdatedAt: now,
      );
      _session = finalizingSession;
      await _persistSession();
      return await _commitFinalization(finalizingSession);
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> discardActiveSession() async {
    if (_session?.finalizing == true) {
      _log('cancelamento ignorado: finalizacao pendente');
      return;
    }
    _timer?.cancel();
    _timer = null;
    _countdownTimer?.cancel();
    _countdownActive = false;
    await _stopGpsStream();
    await StorageService.limparCorridaAtiva();
    _session = null;
    _lastAcceptedPosition = null;
    notifyListeners();
  }

  void _ensureTimer() {
    if (_timer?.isActive ?? false) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = _session;
      if (session == null ||
          session.finished ||
          session.paused ||
          session.finalizing) {
        return;
      }

      final now = _clock();
      _session = _advanceSessionTo(session, now);

      if (elapsedSeconds % 5 == 0) {
        unawaited(_persistSession());
      }

      notifyListeners();
    });
  }

  Future<void> _ensureGpsStream() async {
    if (!_trackGps) return;
    final permissionGranted = await _ensureLocationPermission();
    if (!permissionGranted) {
      _setGpsConnected(false);
      return;
    }

    if (_positionSubscription != null) return;

    try {
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 5,
            ),
          ).listen(
            _handlePosition,
            onError: (Object error) {
              _log('GPS perdido: $error');
              _setGpsConnected(false);
            },
          );
      _setGpsConnected(true);
      _log('GPS conectado');
    } catch (error) {
      _log('GPS perdido: $error');
      _setGpsConnected(false);
    }
  }

  Future<bool> _ensureLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _log('GPS perdido: servico desativado');
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _log('GPS perdido: permissao negada');
        return false;
      }

      return true;
    } catch (error) {
      _log('GPS perdido: $error');
      return false;
    }
  }

  void _handlePosition(Position position) {
    final session = _session;
    if (session == null ||
        session.finished ||
        session.paused ||
        session.finalizing) {
      return;
    }

    final now = _clock();
    final currentSession = _advanceSessionTo(session, now);

    if (position.accuracy > _maxAcceptedAccuracyMeters) {
      return;
    }

    var distanceKm = currentSession.distanceKm;
    var currentSpeed = _speedMpsToKmh(position.speed);
    final previous = _lastAcceptedPosition;

    if (previous != null) {
      final meters = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );
      final seconds = position.timestamp
          .difference(previous.timestamp)
          .inSeconds
          .abs();
      final segmentSpeed = seconds <= 0 ? 0.0 : (meters / seconds) * 3.6;

      if (meters < 0 || segmentSpeed > _maxAcceptedSpeedKmh) {
        return;
      }

      if (meters >= 1) {
        distanceKm += meters / 1000;
        if (currentSpeed <= 0) {
          currentSpeed = segmentSpeed;
        }
      }
    }

    _lastAcceptedPosition = position;
    final route = [
      ...currentSession.route,
      RunningRoutePointModel(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: currentSpeed,
        timestamp: now.toIso8601String(),
      ),
    ];

    _session = _withUpdatedMetrics(
      currentSession.copyWith(
        distanceKm: distanceKm,
        currentSpeed: currentSpeed,
        route: route,
        lastUpdatedAt: now,
      ),
    );
    unawaited(_persistSession());
    notifyListeners();
  }

  RunningSessionModel _restoreElapsedTime(RunningSessionModel session) {
    return _advanceSessionTo(session, _clock());
  }

  /// Usa o timestamp persistido como fonte do cronômetro. O timer apenas
  /// solicita repintura; não é a origem da duração da corrida.
  RunningSessionModel _advanceSessionTo(
    RunningSessionModel session,
    DateTime now,
  ) {
    if (session.finished || session.paused || session.finalizing) {
      return session;
    }
    final delta = now.difference(session.lastUpdatedAt).inSeconds;
    if (delta <= 0) {
      return session;
    }
    return _withUpdatedMetrics(
      session.copyWith(
        elapsedSeconds: session.elapsedSeconds + delta,
        lastUpdatedAt: now,
      ),
    );
  }

  int _pausedSeconds(RunningSessionModel session, DateTime now) {
    final pausedAt = session.pausedAt;
    if (pausedAt == null) return 0;
    final seconds = now.difference(pausedAt).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  RunningSessionModel _withUpdatedMetrics(RunningSessionModel session) {
    final distance = math.max(0.0, session.distanceKm);
    final elapsed = math.max(0, session.elapsedSeconds);
    final averageSpeed = elapsed <= 0 ? 0.0 : distance / (elapsed / 3600);
    final pace = distance <= 0 || elapsed <= 0
        ? 0.0
        : (elapsed / 60) / distance;

    return session.copyWith(
      distanceKm: distance,
      elapsedSeconds: elapsed,
      averageSpeed: averageSpeed,
      pace: pace,
    );
  }

  Future<void> _persistSession() async {
    final session = _session;
    if (session == null) return;

    await StorageService.salvarRunningSessionAtiva(session);
  }

  /// Conclui uma sessão que já foi marcada e persistida como finalizando.
  /// Se o processo cair antes desta etapa, [initialize] tenta novamente com o
  /// mesmo identificador, e o upsert evita duplicar a corrida.
  Future<CorridaModel> _commitFinalization(
    RunningSessionModel finalizingSession,
  ) async {
    final corrida = CorridaModel.fromSession(finalizingSession);
    var persisted = false;
    if (corrida.segundos > 0 || corrida.distancia > 0) {
      persisted = true;
      final inserted = await StorageService.salvarCorrida(corrida);
      if (inserted) await _addTotals(corrida);
      if (corrida.distancia >= 10) await StorageService.salvar10Km(true);
      _log('sincronizacao enviada');
    }

    await StorageService.limparCorridaAtiva();
    _session = null;
    _lastAcceptedPosition = null;
    if (persisted) unawaited(_syncRun(corrida));
    return corrida;
  }

  Future<void> _syncPendingRuns() async {
    final pending = await StorageService.carregarCorridasPendentes();
    for (final corrida in pending) {
      await _syncRun(corrida);
    }
  }

  Future<void> _syncRun(CorridaModel corrida) async {
    if (!_syncingRunIds.add(corrida.id)) return;

    try {
      await StorageService.atualizarCorrida(
        corrida.copyWith(syncStatus: RunningSyncStatus.syncing),
      );
      final result = await SyncService.instance.syncRunning([corrida.toJson()]);
      final status = result == RunningSyncDispatchResult.delivered
          ? RunningSyncStatus.synced
          : RunningSyncStatus.queued;
      await StorageService.atualizarCorrida(
        corrida.copyWith(syncStatus: status),
      );
      _log('corrida ${corrida.id} sincronizacao=${status.storageValue}');
    } catch (error) {
      await StorageService.atualizarCorrida(
        corrida.copyWith(syncStatus: RunningSyncStatus.queued),
      );
      _log('sincronizacao pendente: $error');
    } finally {
      _syncingRunIds.remove(corrida.id);
      notifyListeners();
    }
  }

  Future<void> _stopGpsStream() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _setGpsConnected(false);
  }

  Future<void> _addTotals(CorridaModel corrida) async {
    final distanciaTotal = await StorageService.carregarDistanciaTotal();
    final tempoTotal = await StorageService.carregarTempoTotal();
    final totalCorridas = await StorageService.carregarTotalCorridas();

    await StorageService.salvarDistanciaTotal(
      distanciaTotal + math.max(0.0, corrida.distancia),
    );
    await StorageService.salvarTempoTotal(
      tempoTotal + math.max(0, corrida.segundos),
    );
    await StorageService.salvarTotalCorridas(totalCorridas + 1);
  }

  double _speedMpsToKmh(double speed) {
    if (speed.isNaN || speed.isInfinite || speed <= 0) return 0;

    return speed * 3.6;
  }

  void _setGpsConnected(bool value) {
    if (_gpsConnected == value) return;

    _gpsConnected = value;
    notifyListeners();
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[RunningSessionService] $message');
    }
  }
}
