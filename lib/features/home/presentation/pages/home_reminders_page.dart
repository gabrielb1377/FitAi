import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../widgets/home_detail_scaffold.dart';
import '../widgets/home_official_components.dart';

class HomeRemindersPage extends StatefulWidget {
  const HomeRemindersPage({super.key, required this.showDeveloperPlaceholders});

  final bool showDeveloperPlaceholders;

  @override
  State<HomeRemindersPage> createState() => _HomeRemindersPageState();
}

class _HomeRemindersPageState extends State<HomeRemindersPage> {
  var _selected = 0;
  late final List<_ReminderItem> _items = widget.showDeveloperPlaceholders
      ? _ReminderItem.developerSamples()
      : [];

  @override
  Widget build(BuildContext context) {
    final visible = _items.where((item) => item.isHabit == (_selected == 1));
    return HomeDetailScaffold(
      title: 'Lembretes',
      subtitle: '',
      actions: [
        FitIconButton(
          icon: FitIcons.add,
          tooltip: 'Adicionar lembrete',
          onPressed: _showUnavailable,
        ),
      ],
      child: HomePageBody(
        children: [
          HomeFilterStrip(
            labels: const ['Lembretes', 'Hábitos'],
            selectedIndex: _selected,
            onSelected: (value) => setState(() => _selected = value),
          ),
          const SizedBox(height: FitSpacing.s16),
          if (visible.isEmpty)
            FitEmptyState(
              icon: Icons.alarm_add_outlined,
              title: _selected == 0
                  ? 'Nenhum lembrete criado'
                  : 'Nenhum hábito criado',
              description:
                  'A persistência de lembretes será conectada em uma etapa futura.',
              actionLabel: 'Adicionar',
              onAction: _showUnavailable,
            )
          else ...[
            const FitSectionHeader(title: 'Hoje'),
            const SizedBox(height: FitSpacing.s12),
            for (final item in visible) ...[
              _ReminderTile(
                item: item,
                onChanged: (enabled) {
                  setState(() => item.enabled = enabled);
                },
                onMore: _showUnavailable,
              ),
              const SizedBox(height: FitSpacing.s8),
            ],
          ],
        ],
      ),
    );
  }

  void _showUnavailable() {
    const FitSnackBar(
      message:
          'A criação de lembretes ainda não possui integração persistente.',
      tone: FitSnackBarTone.info,
    ).show(context);
  }
}

class _ReminderItem {
  _ReminderItem({
    required this.title,
    required this.time,
    required this.frequency,
    required this.icon,
    required this.color,
    required this.isHabit,
  }) : enabled = true;

  final String title;
  final String time;
  final String frequency;
  final IconData icon;
  final Color color;
  final bool isHabit;
  bool enabled;

  static List<_ReminderItem> developerSamples() => [
    _ReminderItem(
      title: 'Treino Upper A',
      time: '18:00',
      frequency: 'Hoje',
      icon: Icons.alarm_rounded,
      color: FitColors.primary,
      isHabit: false,
    ),
    _ReminderItem(
      title: 'Beber água',
      time: '12:00',
      frequency: 'Todos os dias',
      icon: FitIcons.water,
      color: FitColors.info,
      isHabit: true,
    ),
    _ReminderItem(
      title: 'Alongamento',
      time: '20:00',
      frequency: 'Todos os dias',
      icon: Icons.self_improvement_rounded,
      color: FitColors.energy,
      isHabit: true,
    ),
  ];
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.item,
    required this.onChanged,
    required this.onMore,
  });

  final _ReminderItem item;
  final ValueChanged<bool> onChanged;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      variant: FitCardVariant.outlined,
      padding: const EdgeInsets.all(FitSpacing.s12),
      semanticLabel:
          '${item.title}, ${item.time}, ${item.enabled ? 'ativo' : 'inativo'}',
      child: Row(
        children: [
          Container(
            width: FitLayout.avatarMedium,
            height: FitLayout.avatarMedium,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: FitOpacity.selected),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: context.textTheme.titleSmall),
                Text(
                  '${item.time} · ${item.frequency}',
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Semantics(
            toggled: item.enabled,
            label: 'Ativar ${item.title}',
            child: Switch(value: item.enabled, onChanged: onChanged),
          ),
          FitIconButton(
            icon: Icons.more_vert_rounded,
            tooltip: 'Mais opções para ${item.title}',
            onPressed: onMore,
          ),
        ],
      ),
    );
  }
}
