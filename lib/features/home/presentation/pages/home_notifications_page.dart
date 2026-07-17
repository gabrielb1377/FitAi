import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/fitai_notification_model.dart';
import '../widgets/home_detail_scaffold.dart';
import '../widgets/home_notification_tile.dart';

enum HomeNotificationFilter { all, workout, coach, running, steps, system }

class HomeNotificationsPage extends StatefulWidget {
  const HomeNotificationsPage({
    super.key,
    this.initialNotifications,
    this.onReload,
    this.onMarkRead,
    this.onMarkAllRead,
    this.onOpenAction,
    this.isOffline = false,
  });

  final List<FitaiNotificationModel>? initialNotifications;
  final Future<List<FitaiNotificationModel>> Function()? onReload;
  final Future<void> Function(FitaiNotificationModel notification)? onMarkRead;
  final Future<void> Function()? onMarkAllRead;
  final Future<void> Function(FitaiNotificationModel notification)?
  onOpenAction;
  final bool isOffline;

  @override
  State<HomeNotificationsPage> createState() => _HomeNotificationsPageState();
}

class _HomeNotificationsPageState extends State<HomeNotificationsPage> {
  late List<FitaiNotificationModel> _notifications;
  HomeNotificationFilter _filter = HomeNotificationFilter.all;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _notifications = widget.initialNotifications ?? const [];
    if (widget.initialNotifications == null) unawaited(_reload());
  }

  Future<void> _reload() async {
    final loader = widget.onReload;
    if (loader == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notifications = await loader();
      if (mounted) setState(() => _notifications = notifications);
    } on Object {
      if (mounted) {
        setState(() => _error = 'Nao foi possivel atualizar as notificacoes.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(FitaiNotificationModel notification) async {
    await widget.onMarkRead?.call(notification);
    if (!mounted) return;
    setState(() {
      _notifications = [
        for (final item in _notifications)
          item.id == notification.id ? item.copyWith(lida: true) : item,
      ];
    });
    await widget.onOpenAction?.call(notification);
  }

  Future<void> _markAll() async {
    await widget.onMarkAllRead?.call();
    if (!mounted) return;
    setState(() {
      _notifications = [
        for (final item in _notifications) item.copyWith(lida: true),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _notifications.where(_matchesFilter).toList();
    return HomeDetailScaffold(
      title: 'Notificacoes',
      subtitle: 'Atualizacoes relevantes do seu dia.',
      actions: [
        if (_notifications.any((item) => !item.lida))
          TextButton(onPressed: _markAll, child: const Text('Marcar todas')),
      ],
      child: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            if (widget.isOffline) ...[
              FitOfflineState(
                compact: true,
                description: 'Mostrando notificacoes salvas no dispositivo.',
                onRetry: () => _reload(),
              ),
              const SizedBox(height: FitSpacing.s16),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in HomeNotificationFilter.values) ...[
                    FitFilterChip(
                      label: _label(filter),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                    const SizedBox(width: FitSpacing.s8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s20),
            if (_loading) const FitListSkeleton(itemCount: 4),
            if (!_loading && _error != null)
              FitErrorState(error: _error!, onRetry: () => _reload()),
            if (!_loading && _error == null && visible.isEmpty)
              FitEmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Nada por aqui',
                description: _filter == HomeNotificationFilter.system
                    ? 'O app ainda nao possui notificacoes de sistema persistidas.'
                    : 'Nao ha notificacoes nesta categoria.',
              ),
            if (!_loading && _error == null)
              for (final notification in visible) ...[
                HomeNotificationTile(
                  notification: notification,
                  onTap: () => _open(notification),
                ),
                const FitDivider(verticalSpacing: FitSpacing.s4),
              ],
          ],
        ),
      ),
    );
  }

  bool _matchesFilter(FitaiNotificationModel notification) {
    return switch (_filter) {
      HomeNotificationFilter.all => true,
      HomeNotificationFilter.workout =>
        notification.categoria == FitaiNotificationCategoria.treinos ||
            notification.categoria == FitaiNotificationCategoria.agenda,
      HomeNotificationFilter.coach =>
        notification.categoria == FitaiNotificationCategoria.coach ||
            notification.categoria == FitaiNotificationCategoria.evolucao,
      HomeNotificationFilter.running =>
        notification.categoria == FitaiNotificationCategoria.corridas,
      HomeNotificationFilter.steps =>
        notification.categoria == FitaiNotificationCategoria.metas,
      HomeNotificationFilter.system => false,
    };
  }

  String _label(HomeNotificationFilter filter) => switch (filter) {
    HomeNotificationFilter.all => 'Todas',
    HomeNotificationFilter.workout => 'Treino',
    HomeNotificationFilter.coach => 'Coach',
    HomeNotificationFilter.running => 'Corridas',
    HomeNotificationFilter.steps => 'Passos',
    HomeNotificationFilter.system => 'Sistema',
  };
}
