import 'package:flutter/material.dart';

import '../../../models/fitai_recorde_model.dart';
import '../../../services/recorde_service.dart';
import '../../../theme/app_theme.dart';
import '../recordes_page.dart';

class RecordesResumoActionCard extends StatelessWidget {
  const RecordesResumoActionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FitaiRecordeModel>>(
      future: const RecordeService().carregarRecordes(),
      builder: (context, snapshot) {
        final recordes = (snapshot.data ?? const <FitaiRecordeModel>[])
            .take(3)
            .toList();

        return AppGradientCard(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecordesPage()),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.military_tech_rounded, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Central de recordes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.white54),
                  ],
                ),
                const SizedBox(height: 12),
                if (recordes.isEmpty)
                  const Text(
                    'Finalize mais sessoes para desbloquear seus PRs.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else
                  for (final recorde in recordes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFFFFC857),
                            size: 17,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${recorde.titulo}: ${recorde.valorFormatado}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}
