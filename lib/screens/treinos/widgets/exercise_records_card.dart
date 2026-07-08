import 'package:flutter/material.dart';

import '../../../models/exercicio_model.dart';
import '../../../models/fitai_recorde_model.dart';
import '../../../services/recorde_service.dart';
import '../../../theme/app_theme.dart';

class ExerciseRecordsCard extends StatelessWidget {
  final ExercicioModel exercicio;

  const ExerciseRecordsCard({super.key, required this.exercicio});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FitaiRecordeModel>>(
      future: const RecordeService().carregarRecordesExercicio(exercicio),
      builder: (context, snapshot) {
        final recordes = snapshot.data ?? const <FitaiRecordeModel>[];

        return AppGradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.emoji_events_rounded, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Recordes do exercicio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(color: AppColors.primary)
              else if (recordes.isEmpty)
                const Text(
                  'Sem PRs ainda. Registre series para criar suas marcas.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                )
              else
                for (final recorde in recordes.take(3))
                  _ExerciseRecordRow(recorde: recorde),
            ],
          ),
        );
      },
    );
  }
}

class _ExerciseRecordRow extends StatelessWidget {
  final FitaiRecordeModel recorde;

  const _ExerciseRecordRow({required this.recorde});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.military_tech_rounded,
            color: Color(0xFFFFC857),
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              recorde.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            recorde.valorFormatado,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
