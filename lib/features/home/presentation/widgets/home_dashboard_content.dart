import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../states/home_state.dart';
import 'home_header.dart';
import 'home_loading_state.dart';
import 'home_ready_content.dart';

class HomeDashboardContent extends StatelessWidget {
  const HomeDashboardContent({
    super.key,
    required this.state,
    required this.name,
    required this.level,
    required this.xp,
    required this.steps,
    required this.distance,
    required this.runningActive,
    required this.runningSeconds,
    required this.onRefresh,
    required this.onOpenWorkout,
    required this.onCreatePlan,
    required this.onOpenLibrary,
    required this.onOpenRunning,
    required this.onOpenSteps,
    required this.onOpenCoach,
    required this.onOpenGoals,
    required this.onOpenAchievements,
    required this.onOpenNotifications,
    required this.onCustomize,
    required this.onOpenOverview,
    required this.onOpenTodayWorkout,
    required this.onOpenRecentActivity,
    required this.onOpenProgress,
  });

  final HomeState state;
  final String name;
  final int level;
  final int xp;
  final int steps;
  final double distance;
  final bool runningActive;
  final int runningSeconds;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenWorkout;
  final VoidCallback onCreatePlan;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenRunning;
  final VoidCallback onOpenSteps;
  final VoidCallback onOpenCoach;
  final VoidCallback onOpenGoals;
  final VoidCallback onOpenAchievements;
  final VoidCallback onOpenNotifications;
  final VoidCallback onCustomize;
  final VoidCallback onOpenOverview;
  final VoidCallback onOpenTodayWorkout;
  final VoidCallback onOpenRecentActivity;
  final VoidCallback onOpenProgress;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          key: const PageStorageKey('official-home-scroll'),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: HomeHeader(
                name: name,
                currentStreak: state.currentStreak,
                unreadNotifications: state.unreadNotifications,
                onOpenNotifications: onOpenNotifications,
                onCustomize: onCustomize,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                _horizontalPadding(context),
                0,
                _horizontalPadding(context),
                FitSpacing.s64,
              ),
              sliver: SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: FitDuration.normal,
                  child: _buildBody(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (state.status == HomeLoadStatus.loading) {
      return const HomeLoadingState(key: ValueKey('home-loading'));
    }
    if (state.status == HomeLoadStatus.error && !state.hasLocalContent) {
      return FitErrorState(
        key: const ValueKey('home-error'),
        title: 'Home indisponivel',
        error: state.errorMessage ?? 'Nao foi possivel carregar seus dados.',
        details: 'Seus dados locais nao foram alterados.',
        onRetry: () => onRefresh(),
      );
    }

    return HomeReadyContent(
      state: state,
      steps: steps,
      distance: distance,
      xp: xp,
      level: level,
      runningActive: runningActive,
      onRefresh: () => onRefresh(),
      onOpenWorkout: onOpenWorkout,
      onCreatePlan: onCreatePlan,
      onOpenRunning: onOpenRunning,
      onOpenSteps: onOpenSteps,
      onOpenCoach: onOpenCoach,
      onOpenAchievements: onOpenAchievements,
      onOpenOverview: onOpenOverview,
      onOpenTodayWorkout: onOpenTodayWorkout,
      onOpenRecentActivity: onOpenRecentActivity,
      onOpenProgress: onOpenProgress,
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (FitBreakpoints.isLargeTablet(width)) return FitSpacing.s64;
    if (FitBreakpoints.isTablet(width)) return FitSpacing.s32;
    return FitSpacing.s20;
  }
}
