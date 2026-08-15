import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../widgets/home_detail_scaffold.dart';

class HomeCustomizePage extends StatefulWidget {
  const HomeCustomizePage({super.key});

  @override
  State<HomeCustomizePage> createState() => _HomeCustomizePageState();
}

class _HomeCustomizePageState extends State<HomeCustomizePage> {
  final _available = <_DashboardItem>[
    const _DashboardItem('Nutrição', FitIcons.nutrition, false),
    const _DashboardItem('Peso', FitIcons.weight, false),
    const _DashboardItem('Sono', Icons.bedtime_outlined, false),
    const _DashboardItem('Frequência cardíaca', FitIcons.heart, false),
    const _DashboardItem('Água', FitIcons.water, false),
    const _DashboardItem('Clima', Icons.cloud_outlined, false),
  ];
  final _selected = <_DashboardItem>[
    const _DashboardItem('XP do dia', Icons.bolt_rounded, true),
    const _DashboardItem('Treino de hoje', FitIcons.workout, true),
    const _DashboardItem('Passos', FitIcons.steps, true),
    const _DashboardItem('Corrida', FitIcons.running, true),
    const _DashboardItem('Coach FitIA', FitIcons.coach, true),
    const _DashboardItem('Progresso semanal', FitIcons.progress, true),
    const _DashboardItem('Atividade recente', FitIcons.history, true),
  ];

  @override
  Widget build(BuildContext context) {
    return HomeDetailScaffold(
      title: 'Personalizar dashboard',
      subtitle: '',
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(FitSpacing.s16),
        child: FitPrimaryButton(
          label: 'Salvar alterações',
          icon: FitIcons.check,
          fullWidth: true,
          onPressed: _save,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide = constraints.maxWidth >= FitBreakpoints.tablet;
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              FitSpacing.s20,
              FitSpacing.s8,
              FitSpacing.s20,
              FitSpacing.s40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: FitBreakpoints.largeTablet,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reorganize e escolha os widgets do seu dashboard.',
                      style: context.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: FitSpacing.s20),
                    if (sideBySide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _availableSection()),
                          const SizedBox(width: FitSpacing.s16),
                          Expanded(child: _selectedSection()),
                        ],
                      )
                    else ...[
                      _selectedSection(),
                      const SizedBox(height: FitSpacing.s24),
                      _availableSection(),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _availableSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FitSectionHeader(title: 'Widgets disponíveis'),
        const SizedBox(height: FitSpacing.s12),
        FitCard(
          variant: FitCardVariant.outlined,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final item in _available)
                FitDashboardCustomizerTile(
                  title: item.title,
                  enabled: item.enabled,
                  leading: Icon(item.icon, color: FitColors.info),
                  onChanged: (_) => _add(item),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _selectedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FitSectionHeader(title: 'Seu dashboard'),
        const SizedBox(height: FitSpacing.s12),
        FitCard(
          variant: FitCardVariant.outlined,
          padding: EdgeInsets.zero,
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _selected.length,
            onReorderItem: _reorder,
            itemBuilder: (context, index) {
              final item = _selected[index];
              return ReorderableDragStartListener(
                key: ValueKey(item.title),
                index: index,
                child: FitDashboardCustomizerTile(
                  title: item.title,
                  enabled: item.enabled,
                  leading: Icon(
                    item.icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onChanged: (_) => _remove(item),
                  dragHandle: Icon(
                    Icons.drag_handle_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _add(_DashboardItem item) {
    setState(() {
      _available.remove(item);
      _selected.add(item.copyWith(enabled: true));
    });
  }

  void _remove(_DashboardItem item) {
    setState(() {
      _selected.remove(item);
      _available.add(item.copyWith(enabled: false));
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _selected.removeAt(oldIndex);
      _selected.insert(newIndex, item);
    });
  }

  void _save() {
    const FitSnackBar(
      message: 'Preferências aplicadas nesta sessão.',
      tone: FitSnackBarTone.success,
    ).show(context);
  }
}

@immutable
class _DashboardItem {
  const _DashboardItem(this.title, this.icon, this.enabled);

  final String title;
  final IconData icon;
  final bool enabled;

  _DashboardItem copyWith({bool? enabled}) {
    return _DashboardItem(title, icon, enabled ?? this.enabled);
  }
}
