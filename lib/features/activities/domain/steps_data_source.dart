import '../../../models/daily_steps_model.dart';

/// Consulta para uma fonte de passos diária.
class StepsDataQuery {
  const StepsDataQuery({
    required this.from,
    required this.to,
    required this.userId,
    required this.goal,
  });

  final DateTime from;
  final DateTime to;
  final String userId;
  final int goal;
}

/// Contrato para fontes de passos. As integrações de dispositivo e saúde ficam
/// fora deste sprint e devem implementar este contrato sem alterar o domínio.
abstract interface class StepsDataSource {
  Future<List<DailyStepsModel>> read(StepsDataQuery query);
}

/// Fonte em memória para registros explícitos, usada por testes e entradas
/// manuais futuras. Ela não tenta inferir dados de sensores.
class ManualStepsDataSource implements StepsDataSource {
  const ManualStepsDataSource(this.records);

  final List<DailyStepsModel> records;

  @override
  Future<List<DailyStepsModel>> read(StepsDataQuery query) async {
    final first = _day(query.from);
    final last = _day(query.to);
    return records
        .where((record) {
          final date = DateTime.tryParse(record.date);
          if (date == null || record.userId != query.userId) return false;
          final day = _day(date);
          return !day.isBefore(first) && !day.isAfter(last);
        })
        .toList(growable: false);
  }
}

/// Fonte de demonstração exclusiva do Developer Mode.
class SeedStepsDataSource implements StepsDataSource {
  const SeedStepsDataSource({required this.steps, this.days = 7});

  final int steps;
  final int days;

  @override
  Future<List<DailyStepsModel>> read(StepsDataQuery query) async {
    final now = _day(query.to);
    final start = _day(query.from);
    final result = <DailyStepsModel>[];
    final length = days.clamp(1, 31);

    for (var offset = 0; offset < length; offset++) {
      final date = now.subtract(Duration(days: offset));
      if (date.isBefore(start)) continue;
      final adjustment = offset == 0 ? 0 : offset * 425;
      final value = (steps - adjustment).clamp(0, 1 << 30).toInt();
      result.add(
        DailyStepsModel(
          userId: query.userId,
          date: DailyStepsModel.normalizeDateKey(date.toIso8601String()),
          steps: value,
          goal: query.goal,
          source: DailyStepsModel.sourceSeed,
          recordedAt: date,
          updatedAt: date,
          syncStatus: DailyStepsSyncStatus.local,
        ),
      );
    }
    return result;
  }
}

DateTime _day(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}
