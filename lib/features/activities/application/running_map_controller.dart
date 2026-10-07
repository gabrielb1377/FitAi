import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/auth/local_account_data_boundary.dart';
import '../../../models/running_session_model.dart';
import '../../../services/running_location_source.dart';
import '../../../services/running_session_service.dart';

enum RunningMapAvailability {
  initializing,
  ready,
  tilesUnavailable,
  unavailable,
}

/// Read-only projection of the accepted session; never subscribes to GPS.
class RunningMapController extends ChangeNotifier {
  RunningMapController(this.service) {
    service.addListener(_update);
    AccountSessionLifecycle.revision.addListener(_accountChanged);
    _update();
  }

  final RunningSessionService service;
  final _segments = <List<RunningRoutePointModel>>[];
  String? _sessionId;
  String? _hiddenSessionId;
  RunningRoutePointModel? _last;
  var _count = 0;
  var _disposed = false;
  var followUser = true;
  var generation = 0;
  var cameraRevision = 0;
  var providerRevision = 0;
  var routeRevision = 0;
  var processedPointCount = 0;
  var availability = RunningMapAvailability.initializing;
  RunningLocationStatus locationStatus = RunningLocationStatus.idle;

  RunningRoutePointModel? get currentPosition => _last;
  int get pointCount => _count;
  List<List<RunningRoutePointModel>> get segments => UnmodifiableListView(
    _segments.map((segment) => UnmodifiableListView(segment)).toList(),
  );

  void _reset() {
    _segments.clear();
    _last = null;
    _count = 0;
    generation++;
    routeRevision++;
    followUser = true;
  }

  void _accountChanged() {
    _hiddenSessionId = service.session?.id;
    _sessionId = null;
    _reset();
    _notify();
  }

  void _update() {
    if (_disposed) return;
    final id = service.hasActiveSession ? service.session?.id : null;
    final route = id == null || id == _hiddenSessionId
        ? const <RunningRoutePointModel>[]
        : service.route;
    final locationChanged = locationStatus != service.locationStatus;
    locationStatus = service.locationStatus;
    var changed = false;
    if (_sessionId != id ||
        route.length < _count ||
        (_count > 0 && !identical(route[_count - 1], _last))) {
      _reset();
      _sessionId = id;
      changed = true;
    }
    for (var index = _count; index < route.length; index++) {
      final point = route[index];
      // Legacy points have no verified continuity: do not draw invented bridges.
      if (_segments.isEmpty || point.startsSegment != false) {
        _segments.add(<RunningRoutePointModel>[]);
      }
      _segments.last.add(point);
      _last = point;
      _count++;
      processedPointCount++;
      changed = true;
    }
    if (changed) {
      routeRevision++;
      if (followUser && _last != null) cameraRevision++;
    }
    if (changed || locationChanged) _notify();
  }

  void manualCameraInteraction() {
    if (!followUser) return;
    followUser = false;
    _notify();
  }

  void recenter() {
    if (_last == null) return;
    followUser = true;
    cameraRevision++;
    _notify();
  }

  void reportAvailability(RunningMapAvailability value) {
    if (_disposed || availability == value) return;
    availability = value;
    _notify();
  }

  void retryProvider() {
    availability = RunningMapAvailability.initializing;
    providerRevision++;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    service.removeListener(_update);
    AccountSessionLifecycle.revision.removeListener(_accountChanged);
    _segments.clear();
    super.dispose();
  }
}
