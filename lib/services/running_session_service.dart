import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/corrida_model.dart';
import '../models/running_session_model.dart';
import 'storage_service.dart';
import 'sync_service.dart';

class RunningSessionService extends ChangeNotifier {
  RunningSessionService._();

  static final RunningSessionService instance = RunningSessionService._();

  static const int _defaultCountdownSeconds = 3;
  static const double _maxAcceptedSpeedKmh = 36;
  static const double _maxAcceptedAccuracyMeters = 60;

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
  DateTime? _lastTickAt;
  Position? _lastAcceptedPosition;

  bool get initialized => _initialized;
  bool get saving => _saving;
  bool get gpsConnected => _gpsConnected;
  bool get countdownActive => _countdownActive;
  int get countdownSeconds => _countdownSeconds;
  RunningSessionModel? get session => _session;
  bool get hasActiveSession => _session != null && !_session!.finished;
  bool get isRunning =>
      hasActiveSession && !_session!.paused && !_countdownActive;
  bool get isPaused => hasActiveSession && _session!.paused;
  bool get isFinished => _session?.finished == true;
  int get elapsedSeconds => _session?.elapsedSeconds ?? 0;
  double get distanceKm => _session?.distanceKm ?? 0;
  double get currentSpeed => _session?.currentSpeed ?? 0;
  double get averageSpeed => _session?.averageSpeed ?? 0;
  double get pace => _session?.pace ?? 0;
  double get calories => _session?.calories ?? 0;
  List<RunningRoutePointModel> get route => _session?.route ?? const [];

  Future<void> initialize() async {
    if (_initialized || _initializing) return;

    _initializing = true;

    final restored = await StorageService.carregarRunningSessionAtiva();

    if (restored != null && !restored.finished) {
      _session = _restoreElapsedTime(restored);
      _lastTickAt = DateTime.now();
      _lastAcceptedPosition = null;

      if (!_session!.paused) {
        _ensureTimer();
        unawaited(_ensureGpsStream());
      }

      _log('sessao restaurada');
      await _persistSession();
    }

    _initialized = true;
    _initializing = false;
    notifyListeners();
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

    final now = DateTime.now();
    _session = RunningSessionModel.start(
      id: 'run_${now.microsecondsSinceEpoch}',
      startTime: now,
    );
    if (!await StorageService.carregarPrimeiraCorrida()) {
      await StorageService.salvarPrimeiraCorrida(true);
    }
    _lastTickAt = now;
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
    if (session == null || session.finished || session.paused) return;

    _timer?.cancel();
    _timer = null;
    await _stopGpsStream();

    _session = session.copyWith(
      paused: true,
      currentSpeed: 0,
      lastUpdatedAt: DateTime.now(),
    );
    await _persistSession();
    _log('corrida pausada');
    notifyListeners();
  }

  Future<void> resume() async {
    final session = _session;
    if (session == null || session.finished || !session.paused) return;

    _session = session.copyWith(
      paused: false,
      clearEndTime: true,
      lastUpdatedAt: DateTime.now(),
    );
    _lastTickAt = DateTime.now();
    await _persistSession();
    _ensureTimer();
    unawaited(_ensureGpsStream());
    _log('corrida retomada');
    notifyListeners();
  }

  Future<CorridaModel?> finish() async {
    if (_saving) return null;

    final session = _session;
    if (session == null || session.finished) return null;

    _saving = true;
    notifyListeners();

    try {
      _timer?.cancel();
      _timer = null;
      _countdownTimer?.cancel();
      _countdownActive = false;
      await _stopGpsStream();

      final finishedSession = _withUpdatedMetrics(session).copyWith(
        endTime: DateTime.now(),
        paused: false,
        finished: true,
        currentSpeed: 0,
        lastUpdatedAt: DateTime.now(),
      );
      final corrida = CorridaModel.fromSession(finishedSession);

      if (corrida.segundos > 0 || corrida.distancia > 0) {
        await StorageService.salvarCorrida(corrida);
        await _addTotals(corrida);
        if (corrida.distancia >= 10) {
          await StorageService.salvar10Km(true);
        }
        _log('sincronizacao enviada');
      }

      await StorageService.limparCorridaAtiva();
      _session = null;
      _lastTickAt = null;
      _lastAcceptedPosition = null;
      unawaited(SyncService.instance.flushPending());

      return corrida;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> discardActiveSession() async {
    _timer?.cancel();
    _timer = null;
    _countdownTimer?.cancel();
    _countdownActive = false;
    await _stopGpsStream();
    await StorageService.limparCorridaAtiva();
    _session = null;
    _lastTickAt = null;
    _lastAcceptedPosition = null;
    notifyListeners();
  }

  void _ensureTimer() {
    if (_timer?.isActive ?? false) return;

    _lastTickAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = _session;
      if (session == null || session.finished || session.paused) return;

      final now = DateTime.now();
      final lastTick = _lastTickAt ?? now;
      final delta = now.difference(lastTick).inSeconds;
      _lastTickAt = now;

      if (delta > 0) {
        _session = _withUpdatedMetrics(
          session.copyWith(
            elapsedSeconds: session.elapsedSeconds + delta,
            lastUpdatedAt: now,
          ),
        );
      }

      if (elapsedSeconds % 5 == 0) {
        unawaited(_persistSession());
      }

      notifyListeners();
    });
  }

  Future<void> _ensureGpsStream() async {
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
    if (session == null || session.finished || session.paused) return;

    if (position.accuracy > _maxAcceptedAccuracyMeters) {
      return;
    }

    var distanceKm = session.distanceKm;
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
      ...session.route,
      RunningRoutePointModel(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: currentSpeed,
        timestamp: DateTime.now().toIso8601String(),
      ),
    ];

    _session = _withUpdatedMetrics(
      session.copyWith(
        distanceKm: distanceKm,
        currentSpeed: currentSpeed,
        route: route,
        lastUpdatedAt: DateTime.now(),
      ),
    );
    unawaited(_persistSession());
    notifyListeners();
  }

  RunningSessionModel _restoreElapsedTime(RunningSessionModel session) {
    if (session.paused || session.finished) return session;

    final now = DateTime.now();
    final delta = now.difference(session.lastUpdatedAt).inSeconds;

    if (delta <= 0) return session;

    return _withUpdatedMetrics(
      session.copyWith(
        elapsedSeconds: session.elapsedSeconds + delta,
        lastUpdatedAt: now,
      ),
    );
  }

  RunningSessionModel _withUpdatedMetrics(RunningSessionModel session) {
    final distance = math.max(0.0, session.distanceKm);
    final elapsed = math.max(0, session.elapsedSeconds);
    final averageSpeed = elapsed <= 0 ? 0.0 : distance / (elapsed / 3600);
    final pace = distance <= 0 || elapsed <= 0
        ? 0.0
        : (elapsed / 60) / distance;
    final calories = distance * 60;

    return session.copyWith(
      distanceKm: distance,
      elapsedSeconds: elapsed,
      averageSpeed: averageSpeed,
      pace: pace,
      calories: calories,
    );
  }

  Future<void> _persistSession() async {
    final session = _session;
    if (session == null) return;

    await StorageService.salvarRunningSessionAtiva(session);
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
