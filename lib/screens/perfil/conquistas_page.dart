import 'package:flutter/material.dart';

import '../../models/achievement_model.dart';
import '../../services/achievement_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';

class ConquistasPage extends StatelessWidget {
  final bool? primeiraCorrida;
  final bool? conquista10Km;
  final int? nivel;

  const ConquistasPage({
    super.key,
    this.primeiraCorrida,
    this.conquista10Km,
    this.nivel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Conquistas")),
      body: FutureBuilder<List<AchievementModel>>(
        future: const AchievementService().carregarConquistas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: AppLoading(message: "Carregando conquistas..."),
            );
          }

          final conquistas = snapshot.data ?? const <AchievementModel>[];

          if (conquistas.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: AppEmptyState(
                icon: Icons.emoji_events_rounded,
                title: "Nenhuma conquista cadastrada",
                message: "Continue treinando para desbloquear marcos no FitIA.",
              ),
            );
          }

          final desbloqueadas = conquistas
              .where((conquista) => conquista.desbloqueada)
              .length;
          final progresso = desbloqueadas / conquistas.length;

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              _horizontalPadding(context),
              20,
              _horizontalPadding(context),
              32,
            ),
            children: [
              _resumo(context, desbloqueadas, conquistas.length, progresso),
              const SizedBox(height: 18),
              for (final categoria in _categorias(conquistas)) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 4),
                  child: Text(
                    categoria,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                for (final conquista in conquistas.where(
                  (item) => item.categoria == categoria,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _conquistaCard(conquista),
                  ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _resumo(
    BuildContext context,
    int desbloqueadas,
    int total,
    double progresso,
  ) {
    final percentual = (progresso * 100).round();

    return AppGradientCard(
      gradient: AppColors.gradientPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.black, size: 34),
          const SizedBox(height: 14),
          const Text(
            "Coleção de conquistas",
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$desbloqueadas de $total desbloqueadas",
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progresso.clamp(0.0, 1.0).toDouble(),
              minHeight: 9,
              color: Colors.black,
              backgroundColor: Colors.black26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$percentual% completo",
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _conquistaCard(AchievementModel conquista) {
    final desbloqueada = conquista.desbloqueada;
    final color = desbloqueada ? AppColors.rankOuro : AppColors.textHint;

    return AppGradientCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(desbloqueada ? 36 : 22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_icone(conquista.icone), color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conquista.nome,
                  style: TextStyle(
                    color: desbloqueada ? Colors.white : Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  conquista.descricao,
                  style: TextStyle(
                    color: desbloqueada ? Colors.white70 : Colors.white38,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                _statusChip(conquista),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(AchievementModel conquista) {
    final desbloqueada = conquista.desbloqueada;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: desbloqueada
            ? AppColors.primary.withAlpha(26)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: desbloqueada ? AppColors.primary : const Color(0xFF2A2A2A),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            desbloqueada ? Icons.check_circle_rounded : Icons.lock_rounded,
            color: desbloqueada ? AppColors.primary : AppColors.textHint,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            desbloqueada
                ? "Desbloqueada ${_formatarData(conquista.data)}"
                : "Bloqueada",
            style: TextStyle(
              color: desbloqueada ? AppColors.primary : AppColors.textHint,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _categorias(List<AchievementModel> conquistas) {
    final categorias = <String>[];

    for (final conquista in conquistas) {
      if (!categorias.contains(conquista.categoria)) {
        categorias.add(conquista.categoria);
      }
    }

    return categorias;
  }

  IconData _icone(String icone) {
    return switch (icone) {
      "fitness_center" => Icons.fitness_center_rounded,
      "format_list_numbered" => Icons.format_list_numbered_rounded,
      "monitor_weight" => Icons.monitor_weight_rounded,
      "local_fire_department" => Icons.local_fire_department_rounded,
      "timer" => Icons.timer_rounded,
      "emoji_events" => Icons.emoji_events_rounded,
      _ => Icons.workspace_premium_rounded,
    };
  }

  String _formatarData(DateTime? data) {
    if (data == null) return "";

    final dia = data.day.toString().padLeft(2, "0");
    final mes = data.month.toString().padLeft(2, "0");
    final ano = data.year.toString();

    return "$dia/$mes/$ano";
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }
}
