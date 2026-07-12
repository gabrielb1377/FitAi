import '../../../models/corrida_model.dart';
import '../../../models/fitai_recorde_model.dart';

class ActivitiesHubData {
  final List<CorridaModel> runs;
  final int workoutsToday;
  final FitaiRecordeModel? lastRecord;

  const ActivitiesHubData({
    required this.runs,
    required this.workoutsToday,
    required this.lastRecord,
  });

  const ActivitiesHubData.empty()
    : runs = const [],
      workoutsToday = 0,
      lastRecord = null;
}
