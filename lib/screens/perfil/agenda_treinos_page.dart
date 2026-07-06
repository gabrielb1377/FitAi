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
  AgendaTreinosMes? _agendaAtual;

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _mesAtual = DateTime(agora.year, agora.month);
    _future = _carregarMes(_mesAtual);
  }

  Future<AgendaTreinosMes> _carregarMes(DateTime mes) async {
    return _service.carregarMes(mes);
  }

  Future<void> _recarregar({DateTime? reabrirDia}) async {
    if (!mounted) return;

    final future = _carregarMes(_mesAtual);
    setState(() {
      _future = future;
    });

    final agenda = await future;
    if (!mounted) return;

    setState(() {
      _agendaAtual = agenda;
    });

    if (reabrirDia != null) {
      _reabrirDiaAtualizado(reabrirDia, agenda);
    }
  }

  void _mudarMes(int delta) {
    final novoMes = DateTime(_mesAtual.year, _mesAtual.month + delta);
    final future = _carregarMes(novoMes);

    setState(() {
      _mesAtual = novoMes;
      _future = future;
    });

    future.then((agenda) {
      if (!mounted || !_mesmaData(_mesAtual, novoMes)) return;

      setState(() {
        _agendaAtual = agenda;
      });
    });
  }

  Future<void> _moverParaAmanha(AgendaDiaTreino dia) async {
    final hoje = DateTime.now();
    final destino = DateTime(hoje.year, hoje.month, hoje.day + 1);

    await _executarAcaoAgenda(
      salvar: () => _service.moverTreino(dia, destino),
      reabrirDia: destino,
      mensagem: 'Treino movido para amanha.',
    );
  }

  Future<void> _reagendar(AgendaDiaTreino dia) async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: dia.data.add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );

    if (selecionada == null) return;
    if (!mounted) return;

    await _executarAcaoAgenda(
      salvar: () => _service.moverTreino(dia, selecionada),
      reabrirDia: selecionada,
      mensagem: 'Treino reagendado.',
    );
  }

  Future<void> _marcarDescanso(AgendaDiaTreino dia) async {
    await _executarAcaoAgenda(
      salvar: () => _service.marcarDescanso(dia),
      reabrirDia: dia.data,
      mensagem: 'Descanso marcado.',
    );
  }

  Future<void> _pularTreino(AgendaDiaTreino dia) async {
    await _executarAcaoAgenda(
      salvar: () => _service.pularTreino(dia),
      reabrirDia: dia.data,
      mensagem: 'Treino pulado.',
    );
  }

  Future<void> _executarAcaoAgenda({
    required Future<void> Function() salvar,
    required DateTime reabrirDia,
    required String mensagem,
  }) async {
    await salvar();
    if (!mounted) return;

    final mesDestino = DateTime(reabrirDia.year, reabrirDia.month);
    if (!_mesmaData(_mesAtual, mesDestino)) {
      setState(() {
        _mesAtual = mesDestino;
      });
    }

    await _recarregar(reabrirDia: reabrirDia);
    if (!mounted) return;

    _mensagem(mensagem);
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

  void _reabrirDiaAtualizado(DateTime data, AgendaTreinosMes agenda) {
    if (!mounted) return;

    final diaAtualizado = _buscarDiaPorData(agenda, data);
    if (diaAtualizado == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _abrirDia(diaAtualizado);
    });
  }

  AgendaDiaTreino? _buscarDiaPorData(AgendaTreinosMes agenda, DateTime data) {
    for (final dia in agenda.dias) {
      if (_mesmaData(dia.data, data)) return dia;
    }

    return null;
  }

  bool _mesmaData(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
            onPressed: () => _recarregar(),
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

          final agenda = snapshot.data ?? _agendaAtual;
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
            onRefresh: () => _recarregar(),
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
