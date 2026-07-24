import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/achievement_model.dart';
import '../widgets/home_detail_scaffold.dart';
import '../widgets/home_official_components.dart';

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
  var _selectedFilter = 0;

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
      subtitle: '',
      actions: [
        FitIconButton(
          icon: Icons.filter_list_rounded,
          tooltip: 'Filtrar conquistas',
          onPressed: () => setState(() => _selectedFilter = 0),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _reload,
        child: HomePageBody(
          children: [
            if (widget.isOffline) ...[
              FitOfflineState(
                compact: true,
                description: 'Mostrando conquistas salvas no dispositivo.',
                onRetry: () => _reload(),
              ),
              const SizedBox(height: FitSpacing.s16),
            ],
            HomeFilterStrip(
              labels: const ['Todas', 'Treino', 'Hábitos', 'Marcos'],
              selectedIndex: _selectedFilter,
              onSelected: (value) {
                setState(() => _selectedFilter = value);
              },
            ),
            const SizedBox(height: FitSpacing.s20),
            if (_loading) const FitListSkeleton(itemCount: 5),
            if (!_loading && _error != null)
              FitErrorState(error: _error!, onRetry: () => _reload()),
            if (!_loading && _error == null) _content(context),
          ],
        ),
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
    final visible = _achievements.where(_matchesFilter).toList();
    final unlocked = _achievements.where((item) => item.desbloqueada).length;
    final recent = visible.where((item) => item.desbloqueada).take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FitCard(
          variant: FitCardVariant.outlined,
          child: FitProgressBar(
            value: _achievements.isEmpty ? 0 : unlocked / _achievements.length,
            label: 'Todas as conquistas',
            trailing: '$unlocked / ${_achievements.length}',
            color: FitColors.achievement,
          ),
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: FitSpacing.s20),
          const FitSectionHeader(
            title: 'Conquistas recentes',
            viewAllLabel: 'Ver todas',
          ),
          const SizedBox(height: FitSpacing.s12),
          HomeMetricGrid(
            preferredColumns: 3,
            items: [
              for (final achievement in recent)
                HomeMetricItem(
                  label: achievement.nome,
                  value: achievement.categoria,
                  detail: achievement.data == null
                      ? null
                      : homeFormatDate(achievement.data!),
                  icon: FitIcons.achievement,
                  color: FitColors.achievement,
                ),
            ],
          ),
        ],
        const SizedBox(height: FitSpacing.s20),
        FitSectionHeader(
          title: 'Todas as conquistas',
          badge: FitBadge(label: '$unlocked / ${_achievements.length}'),
        ),
        const SizedBox(height: FitSpacing.s12),
        if (visible.isEmpty)
          const FitEmptyState(
            icon: FitIcons.achievement,
            title: 'Nenhuma conquista nesta categoria',
            description: 'Escolha outro filtro para continuar.',
          ),
        for (final achievement in visible) ...[
          HomeListAction(
            title: achievement.nome,
            subtitle: achievement.descricao,
            value: achievement.desbloqueada ? 'Concluída' : 'Bloqueada',
            icon: achievement.desbloqueada
                ? FitIcons.achievement
                : FitIcons.lock,
            color: achievement.desbloqueada
                ? FitColors.achievement
                : FitColors.textTertiary,
            progress: achievement.desbloqueada ? 1 : 0,
          ),
          const SizedBox(height: FitSpacing.s8),
        ],
      ],
    );
  }

  bool _matchesFilter(AchievementModel item) {
    if (_selectedFilter == 0) return true;
    final category = item.categoria.toLowerCase();
    return switch (_selectedFilter) {
      1 =>
        category.contains('treino') ||
            category.contains('força') ||
            category.contains('volume'),
      2 =>
        category.contains('consist') ||
            category.contains('hábito') ||
            category.contains('passo'),
      _ =>
        category.contains('record') ||
            category.contains('marco') ||
            category.contains('corrida'),
    };
  }
}
