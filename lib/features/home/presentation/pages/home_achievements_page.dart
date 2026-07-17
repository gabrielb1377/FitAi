import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/achievement_model.dart';
import '../widgets/home_achievement_tile.dart';
import '../widgets/home_detail_scaffold.dart';

class HomeAchievementsPage extends StatefulWidget {
  const HomeAchievementsPage({
    super.key,
    this.initialAchievements,
    this.onReload,
    required this.level,
    required this.xp,
    required this.streak,
    this.isOffline = false,
  });

  final List<AchievementModel>? initialAchievements;
  final Future<List<AchievementModel>> Function()? onReload;
  final int level;
  final int xp;
  final int streak;
  final bool isOffline;

  @override
  State<HomeAchievementsPage> createState() => _HomeAchievementsPageState();
}

class _HomeAchievementsPageState extends State<HomeAchievementsPage> {
  late List<AchievementModel> _achievements;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _achievements = widget.initialAchievements ?? const [];
    if (widget.initialAchievements == null) unawaited(_reload());
  }

  Future<void> _reload() async {
    final loader = widget.onReload;
    if (loader == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final achievements = await loader();
      if (mounted) setState(() => _achievements = achievements);
    } on Object {
      if (mounted) {
        setState(() => _error = 'Nao foi possivel atualizar as conquistas.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeDetailScaffold(
      title: 'Conquistas',
      subtitle: 'Marcos desbloqueados pela sua evolucao real.',
      child: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            if (widget.isOffline) ...[
              FitOfflineState(
                compact: true,
                description: 'Mostrando conquistas salvas no dispositivo.',
                onRetry: () => _reload(),
              ),
              const SizedBox(height: FitSpacing.s16),
            ],
            _summary(context),
            const SizedBox(height: FitSpacing.s24),
            if (_loading) const FitListSkeleton(itemCount: 5),
            if (!_loading && _error != null)
              FitErrorState(error: _error!, onRetry: () => _reload()),
            if (!_loading && _error == null) _content(context),
          ],
        ),
      ),
    );
  }

  Widget _summary(BuildContext context) {
    final unlocked = _achievements.where((item) => item.desbloqueada).length;
    return FitCard(
      variant: FitCardVariant.outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 500 ? 2 : 4;
          final width =
              (constraints.maxWidth - (columns - 1) * FitSpacing.s12) / columns;
          return FitMetricRow(
            spacing: FitSpacing.s12,
            runSpacing: FitSpacing.s16,
            children: [
              SizedBox(
                width: width,
                child: FitMetric(
                  label: 'Nivel',
                  value: '${widget.level}',
                  icon: Icons.workspace_premium_rounded,
                  color: FitColors.achievement,
                ),
              ),
              SizedBox(
                width: width,
                child: FitMetric(
                  label: 'XP',
                  value: '${widget.xp}',
                  icon: Icons.bolt_rounded,
                  color: FitColors.achievement,
                ),
              ),
              SizedBox(
                width: width,
                child: FitMetric(
                  label: 'Sequencia',
                  value: '${widget.streak}',
                  unit: 'dias',
                  icon: Icons.local_fire_department_rounded,
                  color: FitColors.achievement,
                ),
              ),
              SizedBox(
                width: width,
                child: FitMetric(
                  label: 'Liberadas',
                  value: '$unlocked',
                  icon: Icons.emoji_events_rounded,
                  color: FitColors.achievement,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (_achievements.isEmpty) {
      return const FitEmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'Nenhuma conquista disponivel',
        description:
            'Continue registrando atividades para criar seu historico.',
      );
    }
    final categories = <String>{
      for (final achievement in _achievements) achievement.categoria,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final category in categories) ...[
          Text(category, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: FitSpacing.s12),
          for (final achievement in _achievements.where(
            (item) => item.categoria == category,
          )) ...[
            HomeAchievementTile(achievement: achievement),
            const SizedBox(height: FitSpacing.s12),
          ],
          const SizedBox(height: FitSpacing.s12),
        ],
      ],
    );
  }
}
