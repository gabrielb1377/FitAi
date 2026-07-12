import '../../../../models/fitai_meta_model.dart';
import '../../../../models/fitai_recorde_model.dart';
import '../../../../models/historico_treino_model.dart';

class ProfileHubData {
  final int xp;
  final int activeDays;
  final int completedWorkouts;
  final List<FitaiRecordeModel> records;
  final FitaiMetaModel? currentGoal;

  const ProfileHubData({
    required this.xp,
    required this.activeDays,
    required this.completedWorkouts,
    required this.records,
    required this.currentGoal,
  });

  const ProfileHubData.empty()
    : xp = 0,
      activeDays = 0,
      completedWorkouts = 0,
      records = const [],
      currentGoal = null;

  factory ProfileHubData.fromSources({
    required int xp,
    required List<HistoricoTreinoModel> history,
    required List<FitaiRecordeModel> records,
    required FitaiMetasResumo goals,
  }) {
    final activeDays = history
        .map(
          (item) =>
              '${item.dataHora.year}-${item.dataHora.month}-${item.dataHora.day}',
        )
        .toSet()
        .length;
    final activeGoals = goals.metas
        .where((goal) => goal.status != FitaiMetaStatus.concluida)
        .toList();
    final currentGoal = activeGoals.firstOrNull ?? goals.metas.firstOrNull;
    return ProfileHubData(
      xp: xp,
      activeDays: activeDays,
      completedWorkouts: history.length,
      records: records,
      currentGoal: currentGoal,
    );
  }

  String bmi(String weight, String height) {
    final parsedWeight = _number(weight);
    final rawHeight = _number(height);
    final meters = rawHeight > 3 ? rawHeight / 100 : rawHeight;
    if (parsedWeight <= 0 || meters <= 0) return '--';
    return (parsedWeight / (meters * meters)).toStringAsFixed(1);
  }

  static double _number(String value) {
    final match = RegExp(r'(\d+(?:[,.]\d+)?)').firstMatch(value);
    return double.tryParse(match?.group(1)?.replaceAll(',', '.') ?? '') ?? 0;
  }
}

extension on List<FitaiMetaModel> {
  FitaiMetaModel? get firstOrNull => isEmpty ? null : first;
}
