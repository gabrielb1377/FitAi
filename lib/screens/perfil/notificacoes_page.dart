import 'package:flutter/material.dart';

import '../../models/fitai_notification_model.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import 'agenda_treinos_page.dart';
import 'evolucao_page.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_empty_state.dart';
import 'widgets/notification_filter_bar.dart';

class NotificacoesPage extends StatefulWidget {
  final Future<void> Function(FitaiNotificationModel notificacao)? onAbrirAcao;

  const NotificacoesPage({super.key, this.onAbrirAcao});

  @override
  State<NotificacoesPage> createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends State<NotificacoesPage> {
  final _service = const NotificationService();
  FitaiNotificationCategoria? _filtro;
  late Future<List<FitaiNotificationModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.carregarNotificacoes();
  }

  Future<void> _recarregar() async {
    final future = _service.carregarNotificacoes();
    setState(() => _future = future);
    await future;
  }

  Future<void> _marcarTodas() async {
    await _service.marcarTodasComoLidas();
    await _recarregar();
  }

  Future<void> _marcarLida(FitaiNotificationModel notificacao) async {
    await _service.marcarComoLida(notificacao.id);
    await _recarregar();
  }

  Future<void> _excluir(FitaiNotificationModel notificacao) async {
    await _service.excluir(notificacao.id);
    await _recarregar();
  }

  Future<void> _abrir(FitaiNotificationModel notificacao) async {
    await _service.marcarComoLida(notificacao.id);
    if (!mounted) return;
    await _recarregar();

    final callback = widget.onAbrirAcao;
    if (callback != null) {
      await callback(notificacao);
      return;
    }

    if (!mounted) return;
    await _abrirAcaoLocal(notificacao);
  }

  Future<void> _abrirAcaoLocal(FitaiNotificationModel notificacao) async {
    switch (notificacao.acao) {
      case 'agenda':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AgendaTreinosPage()),
        );
        break;
      case 'evolucao':
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const EvolucaoPage()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificacao marcada como lida.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notificacoes'),
        actions: [
          TextButton(
            onPressed: _marcarTodas,
            child: const Text('Marcar todas'),
          ),
        ],
      ),
      body: FutureBuilder<List<FitaiNotificationModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notificacoes =
              snapshot.data ?? const <FitaiNotificationModel>[];
          final filtradas = _filtro == null
              ? notificacoes
              : notificacoes
                    .where((item) => item.categoria == _filtro)
                    .toList();

          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                _horizontalPadding(context),
                16,
                _horizontalPadding(context),
                32,
              ),
              itemCount: filtradas.isEmpty ? 2 : filtradas.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return NotificationFilterBar(
                    filtro: _filtro,
                    onChanged: _setFiltro,
                  );
                }
                if (filtradas.isEmpty) return const NotificationEmptyState();

                final notificacao = filtradas[index - 1];
                return NotificationCard(
                  notificacao: notificacao,
                  onTap: () => _abrir(notificacao),
                  onMarcarLida: () => _marcarLida(notificacao),
                  onExcluir: () => _excluir(notificacao),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _setFiltro(FitaiNotificationCategoria? categoria) {
    setState(() => _filtro = categoria);
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 760) return 36;
    return 18;
  }
}
