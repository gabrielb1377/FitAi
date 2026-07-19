import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../models/fitai_memory_model.dart';
import '../../../models/ready_plan_model.dart';
import '../../../screens/treinos/official/official_plan_ui.dart';
import '../../../services/fitai_memory_service.dart';
import '../../../services/ready_plan_favorites_service.dart';
import '../../../services/ready_plan_recommendation_reason_service.dart';
import '../../../services/ready_plans_service.dart';
import 'ready_plan_preview_page.dart';
import 'widgets/ready_plan_card.dart';
import 'widgets/ready_plans_empty_state.dart';
import 'widgets/ready_plans_loading.dart';

class ReadyPlansLibraryPage extends StatefulWidget {
  const ReadyPlansLibraryPage({
    super.key,
    this.embedded = false,
    this.onShowMyPlans,
    this.service,
  });

  final bool embedded;
  final VoidCallback? onShowMyPlans;
  final ReadyPlansService? service;

  @override
  State<ReadyPlansLibraryPage> createState() => _ReadyPlansLibraryPageState();
}

class _ReadyPlansLibraryPageState extends State<ReadyPlansLibraryPage> {
  late final ReadyPlansService _readyPlansService =
      widget.service ?? ReadyPlansService();
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
        _loading = false;
      });
    } on ReadyPlansException catch (error) {
      _debugLog('Biblioteca indisponivel: ${error.message}');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
        _usingCache = false;
      });
    } catch (error) {
      _debugLog('Falha inesperada ao carregar biblioteca: $error');
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
    ReadyPlanModel previewPlan = plan;
    if (_usingCache) {
      ReadyPlanModel? cachedDetail;
      try {
        cachedDetail = await _readyPlansService.loadPlanDetailCache(plan.id);
      } catch (error) {
        _debugLog('Falha ao ler cache do detalhe ${plan.id}: $error');
      }
      if (!mounted) return;
      if (cachedDetail == null) {
        _debugLog('Cache ausente para detalhe ${plan.id}.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este plano precisa ser aberto online pela primeira vez.',
            ),
          ),
        );
        return;
      }
      _debugLog('Detalhe encontrado no cache: ${plan.id}.');
      previewPlan = cachedDetail;
    }

    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReadyPlanPreviewPage(plan: previewPlan),
      ),
    );

    if (added == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Expanded(child: OfficialPlanSearch(onChanged: _onSearchChanged)),
              const SizedBox(width: 8),
              OfficialPlanIconButton(
                icon: Icons.filter_alt_outlined,
                tooltip: 'Filtros',
                outlined: true,
                onPressed: _showFilters,
              ),
            ],
          ),
        ),
        _buildCacheStatus(context),
        Expanded(child: _buildContent()),
      ],
    );
    if (widget.embedded) return content;
    return Scaffold(
      backgroundColor: OfficialPlanColors.background,
      body: SafeArea(
        bottom: false,
        child: OfficialPlanViewport(
          child: Column(
            children: [
              OfficialPlanHeader(
                title: 'Planos',
                onBack: () => Navigator.maybePop(context),
                trailing: OfficialPlanIconButton(
                  icon: Icons.more_vert_rounded,
                  tooltip: 'Mais opções',
                  onPressed: _showFilters,
                ),
              ),
              OfficialPlanTabs(
                labels: const ['Meus planos', 'Explorar'],
                selectedIndex: 1,
                onSelected: (index) {
                  if (index == 0) {
                    if (widget.onShowMyPlans != null) {
                      widget.onShowMyPlans!();
                    } else {
                      Navigator.maybePop(context);
                    }
                  }
                },
              ),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCacheStatus(BuildContext context) {
    if (!_usingCache) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 15,
            color: OfficialPlanColors.textMuted,
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Mostrando planos salvos no dispositivo.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: OfficialPlanColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Atualizar biblioteca',
            onPressed: _loading ? null : _loadPlans,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.refresh_rounded, size: 17),
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
        final featuredCount = plans.length.clamp(0, 3);

        return RefreshIndicator(
          onRefresh: _loadPlans,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            itemCount: featuredCount + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 2, 0, 8),
                  child: Text(
                    'Em alta',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: OfficialPlanColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }
              if (index == featuredCount + 1) {
                return _objectiveFilters();
              }

              final plan = plans[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
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
              color: OfficialPlanColors.textDim,
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

  Widget _objectiveFilters() {
    const objective = 'Hipertrofia';
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Por objetivo',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: OfficialPlanColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          OfficialPlanSurface(
            padding: const EdgeInsets.all(6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OfficialPlanChoiceChip(
                label: objective,
                selected: _selectedFilter == objective,
                onSelected: () => setState(() {
                  _selectedFilter = _selectedFilter == objective
                      ? 'Todos'
                      : objective;
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilters() async {
    const filters = [
      'Todos',
      'Recomendados',
      'Em destaque',
      'Favoritos',
      'Mais populares',
      'Novos',
    ];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: OfficialPlanColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            for (final filter in filters)
              ListTile(
                minTileHeight: 48,
                title: Text(filter),
                trailing: _selectedFilter == filter
                    ? const Icon(
                        Icons.check_rounded,
                        color: OfficialPlanColors.green,
                      )
                    : null,
                onTap: () => Navigator.pop(sheetContext, filter),
              ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() => _selectedFilter = selected);
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

  void _debugLog(String message) {
    if (kDebugMode) debugPrint('[ReadyPlansLibrary] $message');
  }
}

class _RecommendedPlan {
  final ReadyPlanModel plan;
  final int score;
  final List<String> reasons;

  const _RecommendedPlan(this.plan, this.score, this.reasons);
}
