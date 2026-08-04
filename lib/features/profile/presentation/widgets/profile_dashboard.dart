import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

import '../../domain/profile_models.dart';
import 'profile_achievements_section.dart';
import 'profile_favorites_section.dart';
import 'profile_goals_section.dart';
import 'profile_identity_card.dart';
import 'profile_progression_section.dart';
import 'profile_shortcuts_section.dart';
import 'profile_stats_grid.dart';
import 'profile_summary_section.dart';

/// Dashboard da raiz de Perfil, composto apenas por dados do ProfileSnapshot.
class ProfileDashboard extends StatelessWidget {
  const ProfileDashboard({
    super.key,
    required this.snapshot,
    required this.onRefresh,
    required this.onEdit,
    required this.onSettings,
    required this.onPrivacy,
    required this.onExport,
    required this.onHelp,
    required this.onOpenFavorites,
    required this.onOpenAchievements,
    required this.onConfigureGoals,
  });

  final ProfileSnapshot snapshot;
  final Future<void> Function() onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onSettings;
  final VoidCallback onPrivacy;
  final VoidCallback onExport;
  final VoidCallback onHelp;
  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenAchievements;
  final VoidCallback onConfigureGoals;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              FitSpacing.s20,
              FitSpacing.s16,
              FitSpacing.s20,
              FitSpacing.s32,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: FitBreakpoints.largeTablet,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FitHeader(
                        title: 'Perfil',
                        subtitle: 'Sua evolucao e conquistas.',
                        actions: [
                          FitIconButton(
                            icon: FitIcons.settings,
                            tooltip: 'Abrir configuracoes',
                            onPressed: onSettings,
                          ),
                        ],
                      ),
                      if (snapshot.hasPartialData) ...[
                        const SizedBox(height: FitSpacing.s12),
                        FitOfflineState(
                          compact: true,
                          title: 'Dados locais parciais',
                          description:
                              'Algumas informacoes nao estao disponiveis neste dispositivo.',
                          onRetry: () => onRefresh(),
                        ),
                      ],
                      const SizedBox(height: FitSpacing.s16),
                      ProfileIdentityCard(snapshot: snapshot, onEdit: onEdit),
                      const SizedBox(height: FitSpacing.s24),
                      const FitSectionHeader(title: 'Resumo da evolucao'),
                      const SizedBox(height: FitSpacing.s12),
                      ProfileStatsGrid(stats: snapshot.stats),
                      ProfileSummarySection(stats: snapshot.stats),
                      ProfileProgressionSection(
                        snapshot: snapshot.progression,
                        onViewHistory: onOpenAchievements,
                      ),
                      ProfileGoalsSection(
                        snapshot: snapshot,
                        onConfigure: onConfigureGoals,
                      ),
                      ProfileFavoritesSection(
                        favoriteIds: snapshot.stats.favoriteExerciseIds,
                        onViewAll: onOpenFavorites,
                      ),
                      ProfileAchievementsSection(
                        snapshot: snapshot.progression,
                        onViewAll: onOpenAchievements,
                      ),
                      ProfileShortcutsSection(
                        onEdit: onEdit,
                        onSettings: onSettings,
                        onPrivacy: onPrivacy,
                        onExport: onExport,
                        onHelp: onHelp,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
