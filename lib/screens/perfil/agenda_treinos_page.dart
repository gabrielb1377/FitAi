import 'package:flutter/material.dart';

import '../../services/agenda_treinos_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';
import 'widgets/agenda_treinos_widgets.dart';

class AgendaTreinosPage extends StatefulWidget {
  const AgendaTreinosPage({super.key});

  @override
  State<AgendaTreinosPage> createState() => _AgendaTreinosPageState();
}

class _AgendaTreinosPageState extends State<AgendaTreinosPage> {
  final _service = const AgendaTreinosService();
  late DateTime _mesAtual;
  late Future<AgendaTreinosMes> _future;

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _mesAtual = DateTime(agora.year, agora.month);
    _future = _service.carregarMes(_mesAtual);
  }

  Future<void> _recarregar() async {
    final future = _service.carregarMes(_mesAtual);
    setState(() => _future = future);
    await future;
  }

  void _mudarMes(int delta) {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + delta);
      _future = _service.carregarMes(_mesAtual);
    });
  }

  Future<void> _moverParaAmanha(AgendaDiaTreino dia) async {
    final hoje = DateTime.now();
    await _service.moverTreino(
      dia,
      DateTime(hoje.year, hoje.month, hoje.day + 1),
    );
    await _recarregar();
    _mensagem('Treino movido para amanhã.');
  }

  Future<void> _reagendar(AgendaDiaTreino dia) async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: dia.data.add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );

    if (selecionada == null) return;

    await _service.moverTreino(dia, selecionada);
    await _recarregar();
    _mensagem('Treino reagendado.');
  }

  Future<void> _marcarDescanso(AgendaDiaTreino dia) async {
    await _service.marcarDescanso(dia);
    await _recarregar();
    _mensagem('Descanso marcado.');
  }

  Future<void> _pularTreino(AgendaDiaTreino dia) async {
    await _service.pularTreino(dia);
    await _recarregar();
    _mensagem('Treino pulado.');
  }

  void _abrirDia(AgendaDiaTreino dia) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AgendaDayInfoSheet(
          dia: dia,
          onDescanso: () {
            Navigator.pop(sheetContext);
            _marcarDescanso(dia);
          },
          onReagendar: () {
            Navigator.pop(sheetContext);
            _reagendar(dia);
          },
          onMoverAmanha: () {
            Navigator.pop(sheetContext);
            _moverParaAmanha(dia);
          },
          onPular: () {
            Navigator.pop(sheetContext);
            _pularTreino(dia);
          },
        );
      },
    );
  }

  void _mensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agenda de treinos'),
        actions: [
          IconButton(
            onPressed: _recarregar,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: FutureBuilder<AgendaTreinosMes>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: AppLoading(message: 'Carregando agenda...'),
            );
          }

          final agenda = snapshot.data;
          if (agenda == null) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: AppEmptyState(
                icon: Icons.calendar_month_rounded,
                title: 'Agenda indisponível',
                message: 'Puxe para atualizar e tente novamente.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                _horizontalPadding(context),
                18,
                _horizontalPadding(context),
                36,
              ),
              children: [
                _HeaderMes(
                  mes: _mesAtual,
                  onAnterior: () => _mudarMes(-1),
                  onProximo: () => _mudarMes(1),
                ),
                const SizedBox(height: 16),
                AgendaResumoCard(resumo: agenda.resumo),
                if (agenda.sugestao != null) ...[
                  const SizedBox(height: 16),
                  AgendaCoachCard(
                    sugestao: agenda.sugestao!,
                    onMover: () => _moverParaAmanha(agenda.sugestao!.dia),
                  ),
                ],
                const SizedBox(height: 18),
                AgendaCalendarCard(
                  mes: _mesAtual,
                  dias: agenda.dias,
                  onDiaTap: _abrirDia,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }
}

class _HeaderMes extends StatelessWidget {
  final DateTime mes;
  final VoidCallback onAnterior;
  final VoidCallback onProximo;

  const _HeaderMes({
    required this.mes,
    required this.onAnterior,
    required this.onProximo,
  });

  @override
  Widget build(BuildContext context) {
    return AppGradientCard(
      child: Row(
        children: [
          IconButton(
            onPressed: onAnterior,
            icon: const Icon(Icons.chevron_left_rounded),
            color: Colors.white,
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Calendário inteligente',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${mes.month.toString().padLeft(2, '0')}/${mes.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onProximo,
            icon: const Icon(Icons.chevron_right_rounded),
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
