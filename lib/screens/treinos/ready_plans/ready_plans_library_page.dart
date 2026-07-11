import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/fitai_memory_model.dart';
import '../../../models/ready_plan_model.dart';
import '../../../services/fitai_memory_service.dart';
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
  final _search = ValueNotifier<String>('');

  List<ReadyPlanModel> _plans = const [];
  List<_RecommendedPlan> _recommendations = const [];
  String _selectedFilter = 'Todos';
  bool _loading = true;
  bool _hasError = false;
  bool _usingCache = false;
  DateTime? _cacheUpdatedAt;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPlans());
  }

  @override
  void dispose() {
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
      FitAIMemoryModel memory = const FitAIMemoryModel();

      try {
        memory = await _memoryService.carregarMemoria();
      } catch (_) {
        // A biblioteca continua útil mesmo sem preferências locais.
      }

      if (!mounted) return;
      setState(() {
        _plans = result.plans;
        _recommendations = _recommend(result.plans, memory);
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
    final hasPreferences =
        memory.objetivo.trim().isNotEmpty ||
        memory.nivelExperiencia.trim().isNotEmpty ||
        memory.diasDisponiveis.isNotEmpty ||
        memory.localTreino.trim().isNotEmpty ||
        memory.equipamentos.isNotEmpty;

    if (!hasPreferences) {
      final featured = plans.where((plan) => plan.featured).toList();
      final source = featured.isEmpty ? plans : featured;
      return source.take(3).map((plan) {
        return _RecommendedPlan(plan, 0, 'Plano em destaque na biblioteca.');
      }).toList();
    }

    final scored = plans.map((plan) {
      var score = 0;
      final reasons = <String>[];
      final planText = _normalize(
        [plan.goal, plan.category, plan.split, ...plan.tags].join(' '),
      );

      if (_matches(planText, memory.objetivo)) {
        score += 4;
        reasons.add(
          'Combina com seu objetivo de ${memory.objetivo.toLowerCase()}.',
        );
      }
      if (_matches(_normalize(plan.level), memory.nivelExperiencia)) {
        score += 3;
        reasons.add(
          'Compatível com seu nível ${memory.nivelExperiencia.toLowerCase()}.',
        );
      }
      if (memory.diasDisponiveis.isNotEmpty &&
          plan.daysPerWeek == memory.diasDisponiveis.length) {
        score += 3;
        reasons.add('Ideal para ${plan.daysPerWeek} dias por semana.');
      }
      if (_matches(_normalize(plan.location), memory.localTreino)) {
        score += 2;
        reasons.add('Compatível com seu local de treino.');
      }
      if (plan.equipment.isNotEmpty &&
          memory.equipamentos.isNotEmpty &&
          plan.equipment.any(
            (item) => memory.equipamentos.any(
              (saved) => _matches(_normalize(item), saved),
            ),
          )) {
        score += 1;
        reasons.add('Considera seus equipamentos disponíveis.');
      }

      return _RecommendedPlan(
        plan,
        score,
        reasons.isEmpty
            ? 'Uma opção versátil para sua rotina atual.'
            : reasons.first,
      );
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(3).toList();
  }

  List<ReadyPlanModel> _filteredPlans(String query) {
    final normalizedQuery = _normalize(query);
    return _plans.where((plan) {
      final filterMatches =
          _selectedFilter == 'Todos' ||
          _matches(
            _normalize(
              [plan.category, plan.goal, plan.location, ...plan.tags].join(' '),
            ),
            _selectedFilter,
          );
      if (!filterMatches) return false;
      if (normalizedQuery.isEmpty) return true;

      final searchable = _normalize(
        [
          plan.name,
          plan.goal,
          plan.split,
          plan.category,
          ...plan.tags,
        ].join(' '),
      );
      return searchable.contains(normalizedQuery);
    }).toList();
  }

  Future<void> _openPlan(ReadyPlanModel plan) async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ReadyPlanPreviewPage(plan: plan)),
    );

    if (added == true && mounted) {
      Navigator.pop(context, true);
    }
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
            ReadyPlansSearch(onChanged: (value) => _search.value = value),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 14, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _usingCache
                  ? 'Mostrando planos salvos no dispositivo.'
                  : _cacheUpdatedAt == null
                  ? 'Planos prontos FitIA'
                  : 'Biblioteca atualizada agora',
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
        if (plans.isEmpty) return const ReadyPlansEmptyState();

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
                child: ReadyPlanCard(plan: plan, onTap: () => _openPlan(plan)),
              );
            },
          ),
        );
      },
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
                reason: item.reason,
                onTap: () => _openPlan(item.plan),
              );
            },
          ),
        ),
      ],
    );
  }

  static bool _matches(String source, String target) {
    final normalized = _normalize(target);
    return normalized.isNotEmpty && source.contains(normalized);
  }

  static String _normalize(String value) {
    const source = 'áàãâäéèêëíìîïóòõôöúùûüç';
    const target = 'aaaaaeeeeiiiiooooouuuuc';
    var result = value.toLowerCase().trim();
    for (var index = 0; index < source.length; index++) {
      result = result.replaceAll(source[index], target[index]);
    }
    return result;
  }
}

class _RecommendedPlan {
  final ReadyPlanModel plan;
  final int score;
  final String reason;

  const _RecommendedPlan(this.plan, this.score, this.reason);
}
