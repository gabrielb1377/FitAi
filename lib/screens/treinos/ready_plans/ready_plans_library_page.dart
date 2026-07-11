import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/fitai_memory_model.dart';
import '../../../models/ready_plan_model.dart';
import '../../../services/fitai_memory_service.dart';
import '../../../services/ready_plan_favorites_service.dart';
import '../../../services/ready_plan_recommendation_reason_service.dart';
import '../../../services/ready_plans_service.dart';
import '../../../theme/app_theme.dart';
import 'ready_plan_preview_page.dart';
import 'widgets/ready_plan_card.dart';
import 'widgets/ready_plans_empty_state.dart';
import 'widgets/ready_plans_filters.dart';
import 'widgets/ready_plans_header.dart';
import 'widgets/ready_plans_loading.dart';
import 'widgets/ready_plans_search.dart';
import 'widgets/recommended_plan_card.dart';

class ReadyPlansLibraryPage extends StatefulWidget {
  const ReadyPlansLibraryPage({super.key});

  @override
  State<ReadyPlansLibraryPage> createState() => _ReadyPlansLibraryPageState();
}

class _ReadyPlansLibraryPageState extends State<ReadyPlansLibraryPage> {
  final _readyPlansService = ReadyPlansService();
  final _memoryService = const FitAIMemoryService();
  final _favoritesService = ReadyPlanFavoritesService.instance;
  final _recommendationService = const ReadyPlanRecommendationReasonService();
  final _search = ValueNotifier<String>('');

  List<ReadyPlanModel> _plans = const [];
  List<_RecommendedPlan> _recommendations = const [];
  Timer? _searchDebounce;
  String _selectedFilter = 'Todos';
  bool _loading = true;
  bool _hasError = false;
  bool _usingCache = false;
  DateTime? _cacheUpdatedAt;

  @override
  void initState() {
    super.initState();
    _favoritesService.addListener(_onFavoritesChanged);
    unawaited(_favoritesService.loadFavoriteIds());
    unawaited(_loadPlans());
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_onFavoritesChanged);
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _hasError = false;
      });
    }

    try {
      final result = await _readyPlansService.listPlans();
      final plans = await _readyPlansService.mergeCachedDetails(result.plans);
      FitAIMemoryModel memory = const FitAIMemoryModel();

      try {
        memory = await _memoryService.carregarMemoria();
      } catch (_) {
        // Sem perfil, a recomendacao usa motivos neutros e locais.
      }

      if (!mounted) return;
      setState(() {
        _plans = plans;
        _recommendations = _recommend(plans, memory);
        _usingCache = result.isFromCache;
        _cacheUpdatedAt = result.updatedAt;
        _loading = false;
      });
    } on ReadyPlansException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
        _usingCache = false;
      });
    }
  }

  List<_RecommendedPlan> _recommend(
    List<ReadyPlanModel> plans,
    FitAIMemoryModel memory,
  ) {
    final results = plans.map((plan) {
      final recommendation = _recommendationService.evaluate(plan, memory);
      return _RecommendedPlan(
        plan,
        recommendation.score,
        recommendation.reasons,
      );
    }).toList();

    results.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return b.plan.featured.toString().compareTo(a.plan.featured.toString());
    });
    return results.take(3).toList();
  }

  List<ReadyPlanModel> _filteredPlans(String query) {
    final normalizedQuery = _normalize(query);
    final recommendedIds = _recommendations.map((item) => item.plan.id).toSet();
    final filtered = _plans.where((plan) {
      final filterMatches = switch (_selectedFilter) {
        'Todos' => true,
        'Recomendados' => recommendedIds.contains(plan.id),
        'Em destaque' => plan.featured,
        'Favoritos' => _favoritesService.isFavorite(plan.id),
        'Mais populares' || 'Novos' => true,
        _ => _matches(
          _normalize(
            [plan.category, plan.goal, plan.location, ...plan.tags].join(' '),
          ),
          _selectedFilter,
        ),
      };
      if (!filterMatches) return false;
      return normalizedQuery.isEmpty ||
          _normalize(_searchableContent(plan)).contains(normalizedQuery);
    }).toList();

    if (_selectedFilter == 'Mais populares') {
      filtered.sort((a, b) => b.popularityCount.compareTo(a.popularityCount));
    } else if (_selectedFilter == 'Novos') {
      filtered.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
    }

    return filtered;
  }

  String _searchableContent(ReadyPlanModel plan) {
    return [
      plan.name,
      plan.goal,
      plan.level,
      plan.split,
      plan.location,
      plan.category,
      '${plan.daysPerWeek} dias',
      ...plan.tags,
      ...plan.allEquipment,
      ...plan.primaryMuscleGroups,
      for (final day in plan.days) ...[
        day.name,
        day.title,
        day.muscleGroup,
        for (final exercise in day.exercises) ...[
          exercise.exerciseName,
          exercise.category,
          ...exercise.equipment,
          ...exercise.muscles,
        ],
      ],
    ].join(' ');
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      _search.value = value;
    });
  }

  void _toggleFavorite(ReadyPlanModel plan) {
    unawaited(_favoritesService.toggleFavorite(plan.id));
  }

  Future<void> _openPlan(ReadyPlanModel plan) async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ReadyPlanPreviewPage(plan: plan)),
    );

    if (added == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ReadyPlansHeader(
              title: 'Planos prontos',
              subtitle: 'Encontre uma rotina para o seu momento.',
            ),
            ReadyPlansSearch(onChanged: _onSearchChanged),
            ReadyPlansFilters(
              selected: _selectedFilter,
              onSelected: (filter) => setState(() => _selectedFilter = filter),
            ),
            _buildCacheStatus(context),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheStatus(BuildContext context) {
    final status = _usingCache
        ? 'Dados salvos no dispositivo'
        : _cacheUpdatedAt == null
        ? 'Planos prontos FitIA'
        : 'Biblioteca atualizada agora';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 14, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _usingCache
                    ? AppColors.textSecondary
                    : AppColors.textHint,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _loading ? null : _loadPlans,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const ReadyPlansLoading();
    }
    if (_hasError) {
      return ReadyPlansEmptyState(isError: true, onRetry: _loadPlans);
    }

    return ValueListenableBuilder<String>(
      valueListenable: _search,
      builder: (context, query, _) {
        final plans = _filteredPlans(query);
        if (plans.isEmpty) return _buildEmptyFilter();

        return RefreshIndicator(
          onRefresh: _loadPlans,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 104),
            itemCount: plans.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) return _buildRecommendations(context);
              if (index == 1) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
                  child: Text(
                    'Todos os planos',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                );
              }

              final plan = plans[index - 2];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ReadyPlanCard(
                  plan: plan,
                  onTap: () => _openPlan(plan),
                  isFavorite: _favoritesService.isFavorite(plan.id),
                  onFavoriteToggle: () => _toggleFavorite(plan),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyFilter() {
    if (_selectedFilter != 'Favoritos') return const ReadyPlansEmptyState();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_border_rounded,
              color: AppColors.textHint,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              'Você ainda não favoritou nenhum plano.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => setState(() => _selectedFilter = 'Todos'),
              child: const Text('Explorar planos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    if (_recommendations.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recomendado para você',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 184,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = _recommendations[index];
              return RecommendedPlanCard(
                plan: item.plan,
                reason: item.reasons.first,
                onTap: () => _openPlan(item.plan),
                isFavorite: _favoritesService.isFavorite(item.plan.id),
                onFavoriteToggle: () => _toggleFavorite(item.plan),
              );
            },
          ),
        ),
      ],
    );
  }

  static bool _matches(String source, String value) {
    final target = _normalize(value);
    return target.isNotEmpty && source.contains(target);
  }

  static String _normalize(String value) {
    const source = 'áàãâäéèêëíìîïóòõôöúùûüç';
    const target = 'aaaaaeeeeiiiiooooouuuuc';
    var result = value.toLowerCase().trim();
    for (var index = 0; index < source.length; index += 1) {
      result = result.replaceAll(source[index], target[index]);
    }
    return result;
  }
}

class _RecommendedPlan {
  final ReadyPlanModel plan;
  final int score;
  final List<String> reasons;

  const _RecommendedPlan(this.plan, this.score, this.reasons);
}
