import 'package:flutter/material.dart';

class WorkoutHistoryEntry {
  final int numero;
  final String peso;
  final int repeticoes;
  final DateTime data;

  const WorkoutHistoryEntry({
    required this.numero,
    required this.peso,
    required this.repeticoes,
    required this.data,
  });
}

class ExerciseHistoryCard extends StatelessWidget {
  final List<WorkoutHistoryEntry> entries;

  const ExerciseHistoryCard({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1218),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1D2A35)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, color: Color(0xFF00E5C3)),
              SizedBox(width: 8),
              Text(
                'HistÃ³rico',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              'Registre a primeira sÃ©rie para criar histÃ³rico deste exercÃ­cio.',
              style: TextStyle(
                color: Colors.white.withAlpha(135),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...entries.take(5).map(_HistoryRow.new),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final WorkoutHistoryEntry entry;

  const _HistoryRow(this.entry);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF111820),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${entry.numero}',
                style: const TextStyle(
                  color: Color(0xFF00E5C3),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${entry.peso} kg Ã— ${entry.repeticoes} reps',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            _hora(entry.data),
            style: TextStyle(
              color: Colors.white.withAlpha(120),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static String _hora(DateTime data) {
    final h = data.hour.toString().padLeft(2, '0');
    final m = data.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
