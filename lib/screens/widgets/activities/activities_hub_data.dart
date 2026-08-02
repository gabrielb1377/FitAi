import '../../../models/corrida_model.dart';

class ActivitiesHubData {
  final List<CorridaModel> runs;

  const ActivitiesHubData({required this.runs});

  const ActivitiesHubData.empty() : runs = const [];
}
